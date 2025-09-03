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

#import "LDEApplicationWorkspace.h"
#import "../LiveContainer/zip.h"

@interface LDEApplicationWorkspace ()

@property (nonatomic,strong) NSString *applicationsPath;
@property (nonatomic,strong) NSString *containersPath;

@end

@implementation LDEApplicationWorkspace

/*
 Init
 */
- (instancetype)init
{
    self = [super init];
    
    // Setting up paths
    self.applicationsPath = [NSString stringWithFormat:@"%@/Documents/Applications", NSHomeDirectory()];
    self.containersPath = [NSString stringWithFormat:@"%@/Documents/Containers", NSHomeDirectory()];
    
    // Creating paths if they dont exist
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:self.applicationsPath])
        [fileManager createDirectoryAtPath:self.applicationsPath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    
    if(![fileManager fileExistsAtPath:self.containersPath])
        [fileManager createDirectoryAtPath:self.containersPath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    
    return self;
}

+ (LDEApplicationWorkspace*)shared
{
    static LDEApplicationWorkspace *applicationWorkspaceSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        applicationWorkspaceSingleton = [[LDEApplicationWorkspace alloc] init];
    });
    return applicationWorkspaceSingleton;
}

/*
 Helper
 */
- (NSArray<NSBundle*>*)applicationBundleList
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *uuidPaths = [fileManager contentsOfDirectoryAtPath:self.applicationsPath error:nil];
    NSMutableArray<NSBundle*> *applicationBundleList = [[NSMutableArray alloc] init];
    for(NSString *uuidPath in uuidPaths)
    {
        NSString *bundlePath = [NSString stringWithFormat:@"%@/%@", self.applicationsPath, uuidPath];
        [applicationBundleList addObject:[NSBundle bundleWithPath:bundlePath]];
    }
    return applicationBundleList;
}

/*
 Action
 */
NSString *fileTreeAtPathWithArrows(NSString *path);
- (BOOL)installApplicationAtBundlePath:(NSString*)bundlePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Getting bundle at bundlePath
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    if(!bundle) return NO;
    
    // Now generating new path or using old path
    NSString *installPath = nil;
    NSBundle *previousApplication = [self applicationBundleForBundleID:bundle.bundleIdentifier];
    if(previousApplication) {
        // It existed before, using old path
        [fileManager removeItemAtPath:previousApplication.bundlePath error:nil];
        installPath = previousApplication.bundlePath;
        previousApplication = nil;
    } else {
        // It didnt existed before, using new path
        installPath = [NSString stringWithFormat:@"%@/%@", self.applicationsPath,[[NSUUID UUID] UUIDString]];
    }
    
    // Now installing at install location
    [fileManager moveItemAtPath:bundle.bundlePath toPath:installPath error:nil];
    
    return YES;
}

- (BOOL)deleteApplicationWithBundleID:(NSString *)bundleID
{
    NSBundle *previousApplication = [self applicationBundleForBundleID:bundleID];
    if(previousApplication)
    {
        NSString *container = [self applicationContainerForBundleID:bundleID];
        [[NSFileManager defaultManager] removeItemAtPath:previousApplication.bundlePath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:container error:nil];
        return YES;
    }
    return NO;
}

- (BOOL)applicationInstalledWithBundleID:(NSString*)bundleID
{
    NSArray<NSBundle*> *bundleList = [self applicationBundleList];
    for(NSBundle *bundle in bundleList) if([bundle.bundleIdentifier isEqualToString:bundleID]) return YES;
    return NO;
}

- (NSBundle*)applicationBundleForBundleID:(NSString *)bundleID
{
    NSArray<NSBundle*> *bundleList = [self applicationBundleList];
    for(NSBundle *bundle in bundleList) if([bundle.bundleIdentifier isEqualToString:bundleID]) return bundle;
    return NULL;
}

- (NSString*)applicationContainerForBundleID:(NSString *)bundleID
{
    NSBundle *bundle = [self applicationBundleForBundleID:bundleID];
    NSString *uuid = [bundle.bundleURL lastPathComponent];
    return [NSString stringWithFormat:@"%@/%@", self.containersPath, uuid];
}

@end

@implementation LDEApplicationWorkspaceProxy

- (void)applicationInstalledWithBundleID:(NSString *)bundleID withReply:(void (^)(BOOL))reply {
    reply([[LDEApplicationWorkspace shared] applicationInstalledWithBundleID:bundleID]);
}

- (void)deleteApplicationWithBundleID:(NSString *)bundleID withReply:(void (^)(BOOL))reply {
    reply([[LDEApplicationWorkspace shared] deleteApplicationWithBundleID:bundleID]);
}

- (void)installApplicationAtBundlePath:(NSFileHandle*)bundleHandle withReply:(void (^)(BOOL))reply {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tempBundle = [NSString stringWithFormat:@"%@%@.app", NSTemporaryDirectory(), [[NSUUID UUID] UUIDString]];
    unzipArchiveFromFileHandle(bundleHandle, tempBundle);
    BOOL didInstall = [[LDEApplicationWorkspace shared] installApplicationAtBundlePath:tempBundle];
    [fileManager removeItemAtPath:tempBundle error:nil];
    reply(didInstall);
}

- (void)applicationObjectForBundleID:(NSString *)bundleID withReply:(void (^)(LDEApplicationObject *))reply
{
    NSBundle *bundle = [[LDEApplicationWorkspace shared] applicationBundleForBundleID:bundleID];
    
    if(!bundle)
    {
        reply(nil);
        return;
    }
    
    LDEApplicationObject *appObj = [[LDEApplicationObject alloc] init];
    appObj.bundleIdentifier = bundle.bundleIdentifier;
    appObj.bundlePath = bundle.bundlePath;
    NSString *displayName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!displayName) {
        displayName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
    }
    if (!displayName) {
        displayName = [bundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
    }
    if (!displayName) {
        displayName = @"Unknown App";
    }
    appObj.displayName = displayName;
    appObj.containerPath = [[LDEApplicationWorkspace shared] applicationContainerForBundleID:bundle.bundleIdentifier];
    
    reply(appObj);
}

- (void)applicationContainerForBundleID:(NSString*)bundleID withReply:(void (^)(NSString*))reply
{
    reply([[LDEApplicationWorkspace shared] applicationContainerForBundleID:bundleID]);
}

- (void)allApplicationBundleIDWithReply:(void (^)(NSArray<NSString*>*))reply
{
    NSMutableArray<NSString*> *allBundleIDs = [[NSMutableArray alloc] init];
    NSArray<NSBundle*> *bundle = [[LDEApplicationWorkspace shared] applicationBundleList];
    for(NSBundle *item in bundle)
    {
        [allBundleIDs addObject:item.bundleIdentifier];
    }
    reply(allBundleIDs);
}

@end

/*
 Server mgmt
 */
/*
 Server + Client Side
 */
@interface ServerDelegate : NSObject <NSXPCListenerDelegate>
@end

@interface ServerManager : NSObject
@property (nonatomic, strong) ServerDelegate *serverDelegate;
@property (nonatomic, strong) NSXPCListener *listener;
+ (instancetype)sharedManager;
- (NSXPCListenerEndpoint*)getEndpointForNewConnections;
@end


@implementation ServerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LDEApplicationWorkspaceProxyProtocol)];
    
    LDEApplicationWorkspaceProxy *exportedObject = [LDEApplicationWorkspaceProxy alloc];
    newConnection.exportedObject = exportedObject;
    
    [newConnection resume];
    
    printf("[Host App] Guest app connected\n");
    
    return YES;
}

- (NSXPCListener*)createAnonymousListener
{
    printf("creating new listener\n");
    NSXPCListener *listener = [NSXPCListener anonymousListener];
    listener.delegate = self;
    [listener resume];
    return listener;
}

@end

@implementation ServerManager

+ (instancetype)sharedManager {
    static ServerManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];

        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            sharedInstance.serverDelegate = [[ServerDelegate alloc] init];
            sharedInstance.listener = [sharedInstance.serverDelegate createAnonymousListener];
        //});
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
    return [[ServerManager sharedManager] getEndpointForNewConnections];
}
