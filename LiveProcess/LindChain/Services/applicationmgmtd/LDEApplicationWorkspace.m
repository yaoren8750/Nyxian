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
#import <LindChain/Private/FoundationPrivate.h>
#import <LindChain/ProcEnvironment/Server/Server.h>
#import <LindChain/LiveContainer/zip.h>
#import <LindChain/Multitask/LDEProcessManager.h>
#import <LindChain/LaunchServices/LaunchService.h>

@implementation LDEApplicationWorkspace

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
    zipDirectoryAtPath(bundlePath, temporaryPackage, YES);
    [[LaunchServices shared] execute:^(NSObject<LDEApplicationWorkspaceProxyProtocol> *remoteProxy){
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [remoteProxy installApplicationAtBundlePath:[NSFileHandle fileHandleForReadingAtPath:temporaryPackage] withReply:^(BOOL replyResult){
            result = replyResult;
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    } byEstablishingConnectionToServiceWithServiceIdentifier:@"com.cr4zy.appmanagementd" compliantToProtocol:@protocol(LDEApplicationWorkspaceProxyProtocol)];
    return result;
}

- (BOOL)installApplicationAtPackagePath:(NSString *)packagePath
{
    __block BOOL result = NO;
    [[LaunchServices shared] execute:^(NSObject<LDEApplicationWorkspaceProxyProtocol> *remoteProxy){
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [remoteProxy installApplicationAtBundlePath:[NSFileHandle fileHandleForReadingAtPath:packagePath] withReply:^(BOOL replyResult){
            result = replyResult;
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    } byEstablishingConnectionToServiceWithServiceIdentifier:@"com.cr4zy.appmanagementd" compliantToProtocol:@protocol(LDEApplicationWorkspaceProxyProtocol)];
    return result;
}

- (BOOL)deleteApplicationWithBundleID:(NSString *)bundleID
{
    __block BOOL result = NO;
    [[LaunchServices shared] execute:^(NSObject<LDEApplicationWorkspaceProxyProtocol> *remoteProxy){
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [remoteProxy deleteApplicationWithBundleID:bundleID withReply:^(BOOL replyResult){
            result = replyResult;
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    } byEstablishingConnectionToServiceWithServiceIdentifier:@"com.cr4zy.appmanagementd" compliantToProtocol:@protocol(LDEApplicationWorkspaceProxyProtocol)];
    return result;
}

- (BOOL)applicationInstalledWithBundleID:(NSString *)bundleID
{
    __block BOOL result = NO;
    [[LaunchServices shared] execute:^(NSObject<LDEApplicationWorkspaceProxyProtocol> *remoteProxy){
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [remoteProxy applicationInstalledWithBundleID:bundleID withReply:^(BOOL replyResult){
            result = replyResult;
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    } byEstablishingConnectionToServiceWithServiceIdentifier:@"com.cr4zy.appmanagementd" compliantToProtocol:@protocol(LDEApplicationWorkspaceProxyProtocol)];
    return result;
}

- (LDEApplicationObject*)applicationObjectForBundleID:(NSString*)bundleID
{
    __block LDEApplicationObject *result = nil;
    [[LaunchServices shared] execute:^(NSObject<LDEApplicationWorkspaceProxyProtocol> *remoteProxy){
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [remoteProxy applicationObjectForBundleID:bundleID withReply:^(LDEApplicationObject *replyResult){
            result = replyResult;
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    } byEstablishingConnectionToServiceWithServiceIdentifier:@"com.cr4zy.appmanagementd" compliantToProtocol:@protocol(LDEApplicationWorkspaceProxyProtocol)];
    return result;
}

- (NSArray<LDEApplicationObject*>*)allApplicationObjects
{
    __block NSArray<LDEApplicationObject*> *result = nil;
    [[LaunchServices shared] execute:^(NSObject<LDEApplicationWorkspaceProxyProtocol> *remoteProxy){
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [remoteProxy allApplicationObjectsWithReply:^(LDEApplicationObjectArray *replyResult) {
            result = replyResult.applicationObjects;
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    } byEstablishingConnectionToServiceWithServiceIdentifier:@"com.cr4zy.appmanagementd" compliantToProtocol:@protocol(LDEApplicationWorkspaceProxyProtocol)];
    return result;
}

- (BOOL)clearContainerForBundleID:(NSString *)bundleID
{
    __block BOOL result = NO;
    [[LaunchServices shared] execute:^(NSObject<LDEApplicationWorkspaceProxyProtocol> *remoteProxy){
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [remoteProxy clearContainerForBundleID:bundleID withReply:^(BOOL replyResult){
            result = replyResult;
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    } byEstablishingConnectionToServiceWithServiceIdentifier:@"com.cr4zy.appmanagementd" compliantToProtocol:@protocol(LDEApplicationWorkspaceProxyProtocol)];
    return result;
}

@end
