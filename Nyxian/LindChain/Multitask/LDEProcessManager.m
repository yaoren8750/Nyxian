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

#import <Nyxian-Swift.h>
#import <LindChain/Multitask/LDEProcessManager.h>
#import <LindChain/LiveContainer/Tweaks/libproc.h>
#import <LindChain/Services/applicationmgmtd/LDEApplicationWorkspace.h>
#import <LindChain/Multitask/LDEMultitaskManager.h>
#import <LindChain/ProcEnvironment/Server/ServerDelegate.h>
#import <LindChain/ProcEnvironment/Surface/surface.h>

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
    
    // FIXME: Executing LDEApplicationWorkspace twice causes deadlock in this block
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [_extension beginExtensionRequestWithInputItems:@[item] completion:^(NSUUID *identifier) {
        if(identifier) {
            weakSelf.identifier = identifier;
            weakSelf.pid = [self.extension pidForRequestIdentifier:self.identifier];
            RBSProcessPredicate* predicate = [PrivClass(RBSProcessPredicate) predicateMatchingIdentifier:@(weakSelf.pid)];
            weakSelf.processMonitor = [PrivClass(RBSProcessMonitor) monitorWithPredicate:predicate updateHandler:^(RBSProcessMonitor *monitor,
                                                                                                               RBSProcessHandle *handle,
                                                                                                               RBSProcessStateUpdate *update)
                                   {
                // Setting process handle directly from process monitor
                weakSelf.processHandle = handle;
                
                // Interestingly, when a process exits, the process monitor says that there is no state, so we can use that as a logic check
                NSArray<RBSProcessState *> *states = [monitor states];
                if([states count] == 0)
                {
                    // Process dead!
                    [[LDEProcessManager shared] unregisterProcessWithProcessIdentifier:weakSelf.pid];
                }
            }];
        }
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    self.displayName = @"LiveProcess";
    self.bundleIdentifier = [liveProcessBundle bundleIdentifier];
    self.executablePath = [liveProcessBundle executablePath];
    
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
    
    self = [self initWithPath:applicationObject.executablePath withArguments:@[applicationObject.executablePath] withEnvironmentVariables:@{@"HOME": applicationObject.containerPath} withFileActions:nil];
    
    // I know, I know LDEProcess is on the verge of deprecation of being replaced by proc surface, but... yk... we need to match bundleids for now
    self.bundleIdentifier = applicationObject.bundleIdentifier;
    
    return self;
}

- (instancetype)initWithPath:(NSString*)binaryPath
               withArguments:(NSArray *)arguments
    withEnvironmentVariables:(NSDictionary*)environment
             withFileActions:(PosixSpawnFileActionsObject*)fileActions
{
    self = [self initWithItems:@{
        @"endpoint": [ServerDelegate getEndpoint],
        @"mode": @"spawn",
        @"executablePath": binaryPath,
        @"arguments": arguments,
        @"environment": environment,
        @"fileActions": fileActions ? fileActions : [PosixSpawnFileActionsObject empty],
        @"outputFD": [NSFileHandle fileHandleWithStandardOutput]
    }];
    
    self.displayName = [[NSURL fileURLWithPath:binaryPath] lastPathComponent];
    self.executablePath = binaryPath;
    self.fileActions = fileActions;
    
    return self;
}

/*
 Information
 */
- (uid_t)uid
{
    // TODO: Implement it, currently returning mobile user
    // MARK: Most reliable way is to return our own uid, as the likelyhood is very small that the extension has a other
    return getuid();
}

- (gid_t)gid
{
    // TODO: Implement it, currently returning mobile user
    // MARK: Most reliable way is to return our own uid, as the likelyhood is very small that the extension has a other
    return getgid();
}

/*
 Action
 */
- (void)sendSignal:(int)signal
{
    if(signal == SIGSTOP)
        _isSuspended = YES;
    else if(signal == SIGCONT)
        _isSuspended = NO;
    
    [self.extension _kill:signal];
}

- (BOOL)suspend
{
    if(!_audioBackgroundModeUsage)
    {
        [self sendSignal:SIGSTOP];
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)resume
{
    [self sendSignal:SIGCONT];
    return YES;
}

- (BOOL)terminate
{
    [self sendSignal:SIGKILL];
    return YES;
}

- (BOOL)isRunning
{
    return [self.processHandle isValid];
}

- (void)setRequestCancellationBlock:(void(^)(NSUUID *uuid, NSError *error))callback
{
    [_extension setRequestCancellationBlock:callback];
}

- (void)setRequestInterruptionBlock:(void(^)(NSUUID *))callback
{
    [_extension setRequestInterruptionBlock:callback];
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
    
    // Adding our own process as the "kernel"
    LDEProcess *hostApp = [[LDEProcess alloc] init];
    hostApp.displayName = @"Nyxian";
    hostApp.bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    hostApp.executablePath = [[NSBundle mainBundle] executablePath];
    hostApp.pid = 0;
    [self.processes setObject:hostApp forKey:@(0)];
    
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
                       doRestartIfRunning:(BOOL)doRestartIfRunning
{
    for(NSNumber *key in self.processes)
    {
        LDEProcess *process = self.processes[key];
        if(!process || ![process.bundleIdentifier isEqualToString:bundleIdentifier]) continue;
        else
        {
            if(doRestartIfRunning)
            {
                [process terminate];
            }
            else
            {
                [[LDEMultitaskManager shared] openWindowForProcessIdentifier:process.pid];
                return process.pid;
            }
        }
    }
    
    LDEProcess *process = [[LDEProcess alloc] initWithBundleIdentifier:bundleIdentifier];
    if(!process) return 0;
    pid_t pid = process.pid;
    [self.processes setObject:process forKey:@(pid)];
    return pid;
}

- (pid_t)spawnProcessWithBundleIdentifier:(NSString *)bundleIdentifier
{
    return [self spawnProcessWithBundleIdentifier:bundleIdentifier doRestartIfRunning:NO];
}

- (pid_t)spawnProcessWithPath:(NSString*)binaryPath
                withArguments:(NSArray *)arguments
     withEnvironmentVariables:(NSDictionary*)environment
              withFileActions:(PosixSpawnFileActionsObject*)fileActions
{
    LDEProcess *process = [[LDEProcess alloc] initWithPath:binaryPath withArguments:arguments withEnvironmentVariables:environment withFileActions:fileActions];
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
    proc_object_remove_for_pid(pid);
}

- (BOOL)isExecutingProcessWithBundleIdentifier:(NSString*)bundleIdentifier
{
    for(NSNumber *key in self.processes)
    {
        LDEProcess *process = [self.processes objectForKey:key];
        if(process)
        {
            if([process.bundleIdentifier isEqual:bundleIdentifier])
            {
                return YES;
            }
        }
    }
    return NO;
}

@end
