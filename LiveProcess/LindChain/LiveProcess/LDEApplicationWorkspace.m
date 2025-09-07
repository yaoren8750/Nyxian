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
    
    return [self execute] ? self : nil;
}

- (BOOL)execute
{
    NSBundle *liveProcessBundle = [NSBundle bundleWithPath:[NSBundle.mainBundle.builtInPlugInsPath stringByAppendingPathComponent:@"LiveProcess.appex"]];
    if(!liveProcessBundle) {
        return NO;
    }
    
    NSError* error = nil;
    _extension = [NSExtension extensionWithIdentifier:liveProcessBundle.bundleIdentifier error:&error];
    if(error) {
        return NO;
    }
    _extension.preferredLanguages = @[];
    
    NSExtensionItem *item = [NSExtensionItem new];
    item.userInfo = @{
        @"endpoint": [[ServerManager sharedManager] getEndpointForNewConnections],
        @"mode": @"management",
    };
    
    __weak typeof(self) weakSelf = self;
    
    [_extension setRequestInterruptionBlock:^(NSUUID *uuid) {
        dispatch_semaphore_signal(weakSelf.sema);
        weakSelf.proxy = nil;
        [weakSelf execute];
    }];
    
    [_extension beginExtensionRequestWithInputItems:@[item] completion:^(NSUUID *identifier) {}];
    
    return YES;
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
    if(!_proxy) return NO;
    __block BOOL result = NO;
    NSString *temporaryPackage = [NSString stringWithFormat:@"%@%@.ipa", NSTemporaryDirectory(), [[NSUUID UUID] UUIDString]];
    if(zipDirectoryAtPath(bundlePath, temporaryPackage, YES)) {
        [_proxy installApplicationAtBundlePath:[NSFileHandle fileHandleForReadingAtPath:temporaryPackage] withReply:^(BOOL replyResult){
            result = replyResult;
            dispatch_semaphore_signal(self.sema);
        }];
        dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
        [[NSFileManager defaultManager] removeItemAtPath:temporaryPackage error:nil];
    } 
    return result;
}

- (BOOL)installApplicationAtPackagePath:(NSString *)packagePath
{
    if(!_proxy) return NO;
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
    if(!_proxy) return NO;
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
    if(!_proxy) return NO;
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
    if(!_proxy) return [[LDEApplicationObject alloc] init];
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
    if(!_proxy) return @[];
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
