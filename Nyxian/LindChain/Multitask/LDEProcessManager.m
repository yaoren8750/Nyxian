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

#import <LindChain/Multitask/LDEProcessManager.h>
#import <LindChain/LiveProcess/LDEApplicationWorkspace.h>
#import <LindChain/Multitask/LDEMultitaskManager.h>
#import <LindChain/ProcEnvironment/Server/ServerDelegate.h>
#import <mach/mach.h>
#include <mach-o/dyld_images.h>
#import <LindChain/LiveContainer/Tweaks/libproc.h>
#import <Nyxian-Swift.h>

/*
 Process
 */
@implementation LDEProcess

- (instancetype)initWithItems:(NSDictionary*)items
{
    self = [super init];
    
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
    item.userInfo = items;
    
    __typeof(self) weakSelf = self;
    [_extension setRequestCancellationBlock:^(NSUUID *uuid, NSError *error) {
        [[LDEProcessManager shared] unregisterProcessWithProcessIdentifier:weakSelf.pid];
    }];
    [_extension setRequestInterruptionBlock:^(NSUUID *uuid) {
        [[LDEProcessManager shared] unregisterProcessWithProcessIdentifier:weakSelf.pid];
    }];
    
    // FIXME: Executing LDEApplicationWorkspace twice causes deadlock in this block
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [_extension beginExtensionRequestWithInputItems:@[item] completion:^(NSUUID *identifier) {
        if(identifier) {
            self.identifier = identifier;
            self.pid = [self.extension pidForRequestIdentifier:self.identifier];
            RBSProcessPredicate* predicate = [PrivClass(RBSProcessPredicate) predicateMatchingIdentifier:@(self.pid)];
            self.processHandle = [PrivClass(RBSProcessHandle) handleForPredicate:predicate error:nil];
        }
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    self.displayName = @"LiveProcess";
    self.bundleIdentifier = [liveProcessBundle bundleIdentifier];
    
    return self;
}

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
{
    LDEApplicationObject *applicationObject = [[LDEApplicationWorkspace shared] applicationObjectForBundleID:bundleIdentifier];
    if(!applicationObject.isLaunchAllowed)
    {
        [NotificationServer NotifyUserWithLevel:NotifLevelError notification:[NSString stringWithFormat:@"\"%@\" Is No Longer Available", applicationObject.displayName] delay:0.0];
        return nil;
    }
    
    self = [self initWithItems:@{
        @"endpoint": [ServerDelegate getEndpoint],
        @"mode": @"application",
        @"appObject": applicationObject,
        @"debugEnabled": @(NO)
    }];
    
    self.displayName = applicationObject.displayName;
    self.bundleIdentifier = applicationObject.bundleIdentifier;
    
    return self;
}

/*
 Information
 */
- (NSString*)executablePath
{
    // FIXME: Use environment libproc when its ready
    pid_t childPid = [self pid];
    char buf[120];
    proc_pidpath(childPid, buf, 120);
    return [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
}

- (uid_t)uid
{
    // TODO: Implement it, currently returning mobile user
    return 501;
}

- (gid_t)gid
{
    // TODO: Implement it, currently returning mobile user
    return 501;
}

/*
 Action
 */
- (BOOL)suspend
{
    [_extension _kill:SIGSTOP];
    return YES;
}

- (BOOL)resume
{
    [_extension _kill:SIGCONT];
    return YES;
}

- (BOOL)terminate
{
    [_extension _kill:SIGKILL];
    return YES;
}

- (BOOL)isRunning
{
    return self.pid > 0 && getpgid(self.pid) > 0;
}

- (void)setRequestCancellationBlock:(void(^)(NSUUID *uuid, NSError *error))callback
{
    __weak typeof(self) weakSelf = self;
    [_extension setRequestCancellationBlock:^(NSUUID *uuid, NSError *error) {
        [[LDEProcessManager shared] unregisterProcessWithProcessIdentifier:weakSelf.pid];
        callback(uuid, error);
    }];
}

- (void)setRequestInterruptionBlock:(void(^)(NSUUID *))callback
{
    __weak typeof(self) weakSelf = self;
    [_extension setRequestInterruptionBlock:^(NSUUID *uuid) {
        [[LDEProcessManager shared] unregisterProcessWithProcessIdentifier:weakSelf.pid];
        callback(uuid);
    }];
}

@end

/*
 Process Manager
 */
@implementation LDEProcessManager

- (instancetype)init
{
    self = [super init];
    self.processes = [[NSMutableDictionary alloc] init];
    return self;
}

+ (instancetype)shared
{
    static LDEProcessManager *processManagerSingletone = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        processManagerSingletone = [[LDEProcessManager alloc] init];
    });
    return processManagerSingletone;
}

/*
 Action
 */
- (pid_t)spawnProcessWithItems:(NSDictionary*)items
{
    LDEProcess *process = [[LDEProcess alloc] initWithItems:items];
    if(!process) return 0;
    pid_t pid = process.pid;
    [self.processes setObject:process forKey:@(pid)];
    return pid;
}

- (pid_t)spawnProcessWithBundleIdentifier:(NSString *)bundleIdentifier
{
    LDEProcess *process = [[LDEProcess alloc] initWithBundleIdentifier:bundleIdentifier];
    if(!process) return 0;
    pid_t pid = process.pid;
    [self.processes setObject:process forKey:@(pid)];
    return pid;
}

- (LDEProcess*)processForProcessIdentifier:(pid_t)pid
{
    return [self.processes objectForKey:@(pid)];
}

- (void)unregisterProcessWithProcessIdentifier:(pid_t)pid
{
    [self.processes removeObjectForKey:@(pid)];
    [[LDEMultitaskManager shared] closeWindowForProcessIdentifier:pid];
}

@end
