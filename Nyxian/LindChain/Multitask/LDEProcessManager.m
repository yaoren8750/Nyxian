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
#import <serverDelegate.h>
#import <mach/mach.h>
#import <LindChain/LiveContainer/Tweaks/libproc.h>

/*
 Process
 */
@implementation LDEProcess

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
{
    self = [super init];
    
    NSBundle *liveProcessBundle = [NSBundle bundleWithPath:[NSBundle.mainBundle.builtInPlugInsPath stringByAppendingPathComponent:@"LiveProcess.appex"]];
    if(!liveProcessBundle) {
        return nil;
    }
    
    // Check if we are even authorized to spawn the task
    LDEApplicationObject *appObj = [[LDEApplicationWorkspace shared] applicationObjectForBundleID:bundleIdentifier];
    if(!appObj.isLaunchAllowed) return nil;
    
    NSError* error = nil;
    _extension = [NSExtension extensionWithIdentifier:liveProcessBundle.bundleIdentifier error:&error];
    if(error) {
        return nil;
    }
    _extension.preferredLanguages = @[];
    
    NSExtensionItem *item = [NSExtensionItem new];
    item.userInfo = @{
        @"endpoint": [[ServerManager sharedManager] getEndpointForNewConnections],
        @"mode": @"application",
        @"appObject": appObj,
        @"debugEnabled": @(NO)
    };
    
    __weak typeof(self) weakSelf = self;
    [_extension setRequestCancellationBlock:^(NSUUID *uuid, NSError *error) {
        // TODO: Handle termination
    }];
    [_extension setRequestInterruptionBlock:^(NSUUID *uuid) {
        // TODO: Handle termination
    }];
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [_extension beginExtensionRequestWithInputItems:@[item] completion:^(NSUUID *identifier) {
        if(identifier) {
            self.identifier = identifier;
            pid_t pid = [self.extension pidForRequestIdentifier:self.identifier];
            self.pid = pid;
            
            RBSProcessPredicate* predicate = [PrivClass(RBSProcessPredicate) predicateMatchingIdentifier:@(pid)];
            self.processHandle = [PrivClass(RBSProcessHandle) handleForPredicate:predicate error:nil];
        }
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return self;
}

/*
 Information
 */
- (NSString*)executablePath
{
    pid_t childPid = [self pid];
    char buf[120];
    proc_pidpath(childPid, buf, 120);
    return [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
}

- (pid_t)pid
{
    pid_t pid = 0;
    if(self.rbsTaskPort) pid_for_task([self.rbsTaskPort port], &pid);
    return (pid == 0) ? _pid : pid;
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
    if(self.rbsTaskPort)
    {
        kern_return_t kr = KERN_SUCCESS;
        kr = task_suspend([self.rbsTaskPort port]);
        return (kr == KERN_SUCCESS) ? YES : NO;
    }
    else
    {
        [_extension _kill:SIGSTOP];
        return YES;
    }
}

- (BOOL)resume
{
    if(self.rbsTaskPort)
    {
        kern_return_t kr = KERN_SUCCESS;
        kr = task_resume([self.rbsTaskPort port]);
        return (kr == KERN_SUCCESS) ? YES : NO;
    }
    else
    {
        [_extension _kill:SIGCONT];
        return YES;
    }
}

- (BOOL)terminate
{
    if(self.rbsTaskPort)
    {
        kern_return_t kr = KERN_SUCCESS;
        kr = task_terminate([self.rbsTaskPort port]);
        return (kr == KERN_SUCCESS) ? YES : NO;
    }
    else
    {
        [_extension _kill:SIGKILL];
        return YES;
    }
}

@end

/*
 Process Manager
 */
@implementation LDEProcessManager

- (instancetype)init
{
    self = [super init];
    self.processes = [[NSMutableArray alloc] init];
    return self;
}

+ (instancetype)shared
{
    __block LDEProcessManager *processManagerSingletone = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        processManagerSingletone = [[LDEProcessManager alloc] init];
    });
    return processManagerSingletone;
}

/*
 Action
 */
- (pid_t)spawnProcessWithBundleIdentifier:(NSString *)bundleIdentifier
{
    LDEProcess *process = [[LDEProcess alloc] initWithBundleIdentifier:bundleIdentifier];
    if(!process) return 0;
    [self.processes addObject:process];
    return process.pid;
}

@end
