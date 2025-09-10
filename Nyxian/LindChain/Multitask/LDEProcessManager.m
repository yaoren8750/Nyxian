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
#include <mach-o/dyld_images.h>
#import <LindChain/LiveContainer/Tweaks/libproc.h>
#import <Nyxian-Swift.h>

NSString *task_executable_path_via_dyld(task_t task)
{
    task_dyld_info_data_t dyld_info;
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    kern_return_t kr = task_info(task, TASK_DYLD_INFO,
                                 (task_info_t)&dyld_info, &count);
    if (kr != KERN_SUCCESS) return nil;

    struct dyld_all_image_infos infos = {0};
    vm_size_t outsize = 0;
    kr = vm_read_overwrite(task,
                           (mach_vm_address_t)dyld_info.all_image_info_addr,
                           sizeof(infos),
                           (mach_vm_address_t)&infos,
                           &outsize);
    if (kr != KERN_SUCCESS || outsize < sizeof(uint32_t)) return nil;
    
    struct dyld_image_info info;
    kr = vm_read_overwrite(task,
                           (mach_vm_address_t)infos.infoArray,
                           sizeof(struct dyld_image_info),
                           (mach_vm_address_t)&info,
                           &outsize);
    if (kr != KERN_SUCCESS || outsize < sizeof(uint32_t)) return nil;
    
    char buf[PATH_MAX];
    kr = vm_read_overwrite(task,
                           (mach_vm_address_t)info.imageFilePath,
                           sizeof(buf),
                           (mach_vm_address_t)&buf,
                           &outsize);
    if (kr != KERN_SUCCESS || outsize < sizeof(uint32_t)) return nil;
    
    return [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
}

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

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
{
    LDEApplicationObject *applicationObject = [[LDEApplicationWorkspace shared] applicationObjectForBundleID:bundleIdentifier];
    if(!applicationObject.isLaunchAllowed)
    {
        [NotificationServer NotifyUserWithLevel:NotifLevelError notification:[NSString stringWithFormat:@"\"%@\" Is No Longer Available", applicationObject.displayName] delay:0.0];
        return nil;
    }
    
    self = [self initWithItems:@{
        @"endpoint": [[ServerManager sharedManager] getEndpointForNewConnections],
        @"mode": @"application",
        @"appObject": applicationObject,
        @"debugEnabled": @(NO)
    }];
    
    return self;
}

/*
 Getter
 */
- (RBSMachPort*)rbsTaskPort
{
    if(!_rbsTaskPort) _rbsTaskPort = [[[[[ServerManager sharedManager] serverDelegate] globalProxy] ports] objectForKey:@(_pid)];
    return _rbsTaskPort;
}

/*
 Information
 */
- (NSString*)executablePath
{
    if(self.rbsTaskPort)
    {
        mach_port_t port = [self.rbsTaskPort port];
        NSString *path = task_executable_path_via_dyld(port);
        return path ? path : @"/bin/unknown";
        return @"";
    }
    else
    {
        pid_t childPid = [self pid];
        char buf[120];
        proc_pidpath(childPid, buf, 120);
        return [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
    }
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

- (void)setRequestCancellationBlock:(void(^)(NSUUID *uuid, NSError *error))callback
{
    __weak typeof(self) weakSelf = self;
    [_extension setRequestCancellationBlock:^(NSUUID *uuid, NSError *error) {
        [[[LDEProcessManager shared] processes] removeObjectForKey:@(weakSelf.pid)];
        callback(uuid, error);
    }];
}

- (void)setRequestInterruptionBlock:(void(^)(NSUUID *))callback
{
    __weak typeof(self) weakSelf = self;
    [_extension setRequestInterruptionBlock:^(NSUUID *uuid) {
        [[[LDEProcessManager shared] processes] removeObjectForKey:@(weakSelf.pid)];
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

@end
