/*
 Copyright (C) 2025 cr4zyengineer

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

#import "LDEApplicationWorkspaceInternal.h"
#import "../LiveContainer/zip.h"
#import <Security/Security.h>

/*
 Certificate check
 */
typedef uint32_t SecCSFlags;
typedef struct CF_BRIDGED_TYPE(id) __SecCode *SecCodeRef;
typedef SecCodeRef SecStaticCodeRef;
OSStatus SecStaticCodeCreateWithPath(
    CFURLRef path,
    SecCSFlags flags,
    SecStaticCodeRef *staticCode);
OSStatus SecCodeCopySigningInformation(
    SecStaticCodeRef code,
    SecCSFlags flags,
    CFDictionaryRef *information);
extern const CFStringRef kSecCodeInfoTeamIdentifier
    API_AVAILABLE(macos(10.7));
enum {
      kSecCSDefaultFlags       = 0U,
      kSecCSSigningInformation = (1U << 1),
  };

static NSString *TeamIdentifierForBinary(NSString *path) {
    if (path.length == 0) return nil;

    SecStaticCodeRef codeRef = NULL;
    CFDictionaryRef signingInfo = NULL;
    NSString *teamID = nil;

    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    OSStatus status = SecStaticCodeCreateWithPath(url, kSecCSDefaultFlags, &codeRef);
    if (status != errSecSuccess || codeRef == NULL) goto cleanup;

    status = SecCodeCopySigningInformation(codeRef, kSecCSSigningInformation, &signingInfo);
    if (status != errSecSuccess || signingInfo == NULL) goto cleanup;

    CFStringRef tid = CFDictionaryGetValue(signingInfo, kSecCodeInfoTeamIdentifier);
    if (tid) {
        teamID = [(__bridge NSString *)tid copy];
    }

cleanup:
    if (signingInfo) CFRelease(signingInfo);
    if (codeRef) CFRelease(codeRef);
    return teamID;
}

BOOL BinariesHaveMatchingTeamID(NSString *pathA, NSString *pathB) {
    NSString *teamA = TeamIdentifierForBinary(pathA);
    NSString *teamB = TeamIdentifierForBinary(pathB);
    if (!teamA || !teamB) return NO;
    return [teamA isEqualToString:teamB];
}


/*
 Internal class
 */
@interface LDEApplicationWorkspaceInternal ()

@property (nonatomic,strong) NSURL *applicationsURL;
@property (nonatomic,strong) NSURL *containersURL;

@end

@implementation LDEApplicationWorkspaceInternal

/*
 Init
 */
- (instancetype)init
{
    self = [super init];
    
    // Setting up paths
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    self.applicationsURL = [NSURL fileURLWithPath:[documentsDir stringByAppendingPathComponent:@"Bundle/Application"]];
    self.containersURL   = [NSURL fileURLWithPath:[documentsDir stringByAppendingPathComponent:@"Data/Application"]];
    
    // Creating paths if they dont exist
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:self.applicationsURL.path])
        [fileManager createDirectoryAtURL:self.applicationsURL
              withIntermediateDirectories:YES
                               attributes:nil
                                    error:nil];
    
    if(![fileManager fileExistsAtPath:self.containersURL.path])
        [fileManager createDirectoryAtURL:self.containersURL
              withIntermediateDirectories:YES
                               attributes:nil
                                    error:nil];
    
    return self;
}

+ (LDEApplicationWorkspaceInternal*)shared
{
    static LDEApplicationWorkspaceInternal *applicationWorkspaceSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        applicationWorkspaceSingleton = [[LDEApplicationWorkspaceInternal alloc] init];
    });
    return applicationWorkspaceSingleton;
}

/*
 Helper
 */
- (NSArray<MIBundle*>*)applicationBundleList
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSURL*> *uuidURLs = [fileManager contentsOfDirectoryAtURL:self.applicationsURL includingPropertiesForKeys:nil options:0 error:nil];
    NSMutableArray<MIBundle*> *applicationBundleList = [[NSMutableArray alloc] init];
    for(NSURL *uuidURL in uuidURLs)
    {
        MIBundle *bundle = [[PrivClass(MIBundle) alloc] initWithBundleInDirectory:uuidURL withExtension:@"app" error:nil];
        if(bundle) [applicationBundleList addObject:bundle];
    }
    return applicationBundleList;
}

/*
 Action
 */
- (BOOL)installApplicationWithPayloadPath:(NSString*)payloadPath
{
    // Creating MIBundle of payload
    MIExecutableBundle *bundle = [[PrivClass(MIExecutableBundle) alloc] initWithBundleInDirectory:payloadPath withExtension:@"app" error:nil];
    
    // Check if bundle is valid for LDEApplicationWorkspace
    if(!bundle) return NO;
    else if(![bundle validateBundleMetadataWithError:nil]) return NO;
    else if(![bundle isAppTypeBundle]) return NO;
    else if(![bundle validateAppMetadataWithError:nil]) return NO;
    else if(![bundle isApplicableToCurrentOSVersionWithError:nil]) return NO;
    
    // FIXME: Fix code signature validation
    // MARK: The problem is that the code signature used in this bundle under the conditions of this bundle would of never pass installd
    /*NSError *error = nil;
    id signInfo = [NSClassFromString(@"MICodeSigningVerifier")
                      _validateSignatureAndCopyInfoForURL:[bundle executableURL]
                      withOptions:nil
                      error:&error];

    if (signInfo) {
        NSLog(@"✅ Has a signature: %@", signInfo);
    } else {
        NSLog(@"❌ No signature: %@", error);
    }
    NSLog(@"SIGNING RESULT %@", signInfo);*/
    
    // MARK: Replacement to CS check, check if both teamids match as that is one of the most important indicators, but not if the certificate is outdated, just makes sure they were both signed with a certificate of the same teamid, it also prevents the attempt to run unsigned bundles
    if(!BinariesHaveMatchingTeamID([[NSBundle mainBundle] executablePath], [[bundle executableURL] path])) return NO;
    
    // File manager
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Now generate installPath
    NSURL *installURL = nil;
    MIBundle *previousApplication = [self applicationBundleForBundleID:[bundle identifier]];
    if(previousApplication) {
        // It existed before, using old path
        installURL = previousApplication.bundleURL;
        [fileManager removeItemAtURL:installURL error:nil];
        previousApplication = nil;
    } else {
        // It didnt existed before, using new path
        installURL = [[self.applicationsURL URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]] URLByAppendingPathComponent:[bundle relativePath]];
    }
    
    // Now installing at install location
    if(![fileManager createDirectoryAtURL:[installURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil]) return NO;
    if(![fileManager moveItemAtURL:bundle.bundleURL toURL:installURL error:nil]) return NO;
    
    return YES;
}

- (BOOL)deleteApplicationWithBundleID:(NSString *)bundleID
{
    MIBundle *previousApplication = [self applicationBundleForBundleID:bundleID];
    if(previousApplication)
    {
        NSURL *container = [self applicationContainerForBundleID:bundleID];
        [[NSFileManager defaultManager] removeItemAtURL:[previousApplication bundleURL] error:nil];
        [[NSFileManager defaultManager] removeItemAtURL:container error:nil];
        return YES;
    }
    return NO;
}

- (BOOL)applicationInstalledWithBundleID:(NSString*)bundleID
{
    NSArray<MIBundle*> *bundleList = [self applicationBundleList];
    for(MIBundle *bundle in bundleList) if([bundle.identifier isEqualToString:bundleID]) return YES;
    return NO;
}

- (MIBundle*)applicationBundleForBundleID:(NSString *)bundleID
{
    NSArray<MIBundle*> *bundleList = [self applicationBundleList];
    for(MIBundle *bundle in bundleList) if([bundle.identifier isEqualToString:bundleID]) return bundle;
    return nil;
}

- (NSURL*)applicationContainerForBundleID:(NSString *)bundleID
{
    MIBundle *bundle = [self applicationBundleForBundleID:bundleID];
    if(!bundle) return nil;
    NSString *uuid = [[bundle.bundleURL URLByDeletingLastPathComponent] lastPathComponent];
    return [self.containersURL URLByAppendingPathComponent:uuid];
}

@end

@implementation LDEApplicationWorkspaceProxy

- (void)applicationInstalledWithBundleID:(NSString *)bundleID withReply:(void (^)(BOOL))reply {
    reply([[LDEApplicationWorkspaceInternal shared] applicationInstalledWithBundleID:bundleID]);
}

- (void)deleteApplicationWithBundleID:(NSString *)bundleID withReply:(void (^)(BOOL))reply {
    reply([[LDEApplicationWorkspaceInternal shared] deleteApplicationWithBundleID:bundleID]);
}

- (void)installApplicationAtBundlePath:(NSFileHandle*)bundleHandle withReply:(void (^)(BOOL))reply {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tempBundle = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [[NSUUID UUID] UUIDString]];
    unzipArchiveFromFileHandle(bundleHandle, tempBundle);
    BOOL didInstall = [[LDEApplicationWorkspaceInternal shared] installApplicationWithPayloadPath:tempBundle];
    [fileManager removeItemAtPath:tempBundle error:nil];
    reply(didInstall);
}

- (void)applicationObjectForBundleID:(NSString *)bundleID withReply:(void (^)(LDEApplicationObject *))reply
{
    MIBundle *bundle = [[LDEApplicationWorkspaceInternal shared] applicationBundleForBundleID:bundleID];
    
    if(!bundle)
    {
        reply(nil);
        return;
    }
    
    reply([[LDEApplicationObject alloc] initWithBundle:bundle]);
}

- (void)applicationContainerForBundleID:(NSString*)bundleID withReply:(void (^)(NSURL*))reply
{
    reply([[LDEApplicationWorkspaceInternal shared] applicationContainerForBundleID:bundleID]);
}

- (void)allApplicationBundleIDWithReply:(void (^)(NSArray<NSString*>*))reply
{
    NSMutableArray<NSString*> *allBundleIDs = [[NSMutableArray alloc] init];
    NSArray<MIBundle*> *bundle = [[LDEApplicationWorkspaceInternal shared] applicationBundleList];
    for(MIBundle *item in bundle) [allBundleIDs addObject:item.identifier];
    reply(allBundleIDs);
}

@end

/*
 Server mgmt
 */
/*
 Server + Client Side
 */
@interface LDEServerDelegate : NSObject <NSXPCListenerDelegate>
@end

@interface LDEServerManager : NSObject
@property (nonatomic, strong) LDEServerDelegate *serverDelegate;
@property (nonatomic, strong) NSXPCListener *listener;
+ (instancetype)sharedManager;
- (NSXPCListenerEndpoint*)getEndpointForNewConnections;
@end


@implementation LDEServerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LDEApplicationWorkspaceProxyProtocol)];
    
    LDEApplicationWorkspaceProxy *exportedObject = [[LDEApplicationWorkspaceProxy alloc] init];
    newConnection.exportedObject = exportedObject;
    
    [newConnection resume];
    
    printf("[Host App] Guest app connected\n");
    
    return YES;
}

- (NSXPCListener*)createAnonymousListener
{
    NSXPCListener *listener = [NSXPCListener anonymousListener];
    listener.delegate = self;
    [listener resume];
    return listener;
}

@end

@implementation LDEServerManager

+ (instancetype)sharedManager {
    static LDEServerManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.serverDelegate = [[LDEServerDelegate alloc] init];
        sharedInstance.listener = [sharedInstance.serverDelegate createAnonymousListener];
    });
    return sharedInstance;
}

- (NSXPCListenerEndpoint*)getEndpointForNewConnections
{
    NSXPCListenerEndpoint *endpoint = self.listener.endpoint;
    return endpoint;
}

@end

NSXPCListenerEndpoint *getLDEApplicationWorkspaceProxyEndpoint(void)
{
    return [[LDEServerManager sharedManager] getEndpointForNewConnections];
}
