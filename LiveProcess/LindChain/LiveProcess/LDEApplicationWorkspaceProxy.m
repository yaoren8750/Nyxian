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

#import "LDEApplicationWorkspaceProxy.h"
#import <LindChain/LiveContainer/FoundationPrivate.h>
#import "../../serverDelegate.h"
#import "../LiveContainer/zip.h"

@interface LDEApplicationWorkspace ()

@property (nonatomic,strong,readonly) NSExtension *extension;
@property (nonatomic,strong,readonly) dispatch_semaphore_t sema;

@end

@implementation LDEApplicationWorkspace

- (instancetype)init
{
    self = [super init];
    
    _sema = dispatch_semaphore_create(0);
    
    NSBundle *liveProcessBundle = [NSBundle bundleWithPath:[NSBundle.mainBundle.builtInPlugInsPath stringByAppendingPathComponent:@"LiveProcess.appex"]];
    if(!liveProcessBundle) {
        return nil;
    }
    
    NSError* error = nil;
    _extension = [NSExtension extensionWithIdentifier:liveProcessBundle.bundleIdentifier error:&error];
    if(error) {
        return nil;
    }
    _extension.preferredLanguages = @[];
    
    NSExtensionItem *item = [NSExtensionItem new];
    item.userInfo = @{
        @"endpoint": [[ServerManager sharedManager] getEndpointForNewConnections],
        @"mode": @"management",
    };
    
    [_extension setRequestCancellationBlock:^(NSUUID *uuid, NSError *error) {
        NSLog(@"Extension down!");
    }];
    
    [_extension setRequestInterruptionBlock:^(NSUUID *uuid) {
        NSLog(@"Extension down!");
    }];
    
    [_extension beginExtensionRequestWithInputItems:@[item] completion:^(NSUUID *identifier) {}];
    /*[_extension beginExtensionRequestWithInputItems:@[item] completion:^(NSUUID *identifier) {
        if(identifier) {
            //[MultitaskManager registerMultitaskContainerWithContainer:self.dataUUID];
            //self.identifier = identifier;
            //self.pid = [self.extension pidForRequestIdentifier:self.identifier];
            
            //NSLog(@"child process spawned with %u\n", self.pid);
            [self.delegate appSceneVC:self didInitializeWithError:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setUpAppPresenter];
            });
        } else {
            NSError* error = [NSError errorWithDomain:@"LiveProcess" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Failed to start app. Child process has unexpectedly crashed"}];
            NSLog(@"%@", [error localizedDescription]);
            [self.delegate appSceneVC:self didInitializeWithError:error];
        }
    }];*/
    
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

- (BOOL)installApplicationAtBundlePath:(NSString*)bundlePath
{
    __block BOOL result = NO;
    NSString *temporaryPackage = [NSString stringWithFormat:@"%@%@.ipa", NSTemporaryDirectory(), [[NSUUID UUID] UUIDString]];
    zipDirectoryAtPath(bundlePath, temporaryPackage);
    [_proxy installApplicationAtBundlePath:[NSFileHandle fileHandleForReadingAtPath:temporaryPackage] withReply:^(BOOL replyResult){
        result = replyResult;
        dispatch_semaphore_signal(self.sema);
    }];
    dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
    return result;
}

- (BOOL)installApplicationAtPackagePath:(NSString *)packagePath
{
    __block BOOL result = NO;
    [_proxy installApplicationAtBundlePath:[NSFileHandle fileHandleForReadingAtPath:packagePath] withReply:^(BOOL replyResult){
        result = replyResult;
        dispatch_semaphore_signal(self.sema);
    }];
    dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
    return result;
}

- (BOOL)deleteApplicationWithBundleID:(NSString *)bundleID
{
    __block BOOL result = NO;
    [_proxy deleteApplicationWithBundleID:bundleID withReply:^(BOOL replyResult){
        result = replyResult;
        dispatch_semaphore_signal(self.sema);
    }];
    dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
    return result;
}

- (BOOL)applicationInstalledWithBundleID:(NSString *)bundleID
{
    __block BOOL result = NO;
    [_proxy applicationInstalledWithBundleID:bundleID withReply:^(BOOL replyResult){
        result = replyResult;
        dispatch_semaphore_signal(self.sema);
    }];
    dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
    return result;
}

- (LDEApplicationObject*)applicationObjectForBundleID:(NSString*)bundleID
{
    __block LDEApplicationObject *result = nil;
    [_proxy applicationObjectForBundleID:bundleID withReply:^(LDEApplicationObject *replyResult){
        result = replyResult;
        dispatch_semaphore_signal(self.sema);
    }];
    dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
    return result;
}

- (NSArray<LDEApplicationObject*>*)allApplicationObjects
{
    __block NSMutableArray<LDEApplicationObject*> *allApplicationObjects = [[NSMutableArray alloc] init];
    __block NSArray<NSString*> *result = nil;
    [_proxy allApplicationBundleIDWithReply:^(NSArray<NSString*> *replyResult){
        result = replyResult;
        dispatch_semaphore_signal(self.sema);
    }];
    dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
    
    for(NSString *bundleID in result)
    {
        [_proxy applicationObjectForBundleID:bundleID withReply:^(LDEApplicationObject *replyResult){
            [allApplicationObjects addObject:replyResult];
            dispatch_semaphore_signal(self.sema);
        }];
        dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
    }
    
    return allApplicationObjects;
}

@end

__attribute__((constructor))
void ldeApplicationWorkspaceProxyInit(void)
{
    [LDEApplicationWorkspace shared];
}

