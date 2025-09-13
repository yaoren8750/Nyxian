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
#import <mach/mach.h>
#include <mach-o/dyld_images.h>
#import <LindChain/LiveContainer/Tweaks/libproc.h>

#if __has_include(<Nyxian-Swift.h>)
#import <Nyxian-Swift.h>
#import <LindChain/Services/applicationmgmtd/LDEApplicationWorkspace.h>
#import <LindChain/Multitask/LDEMultitaskManager.h>
#import <LindChain/ProcEnvironment/Server/ServerDelegate.h>
#endif

/*
 Process
 */
@implementation LDEProcess

- (instancetype)initWithItems:(NSDictionary*)items
{
    self = [super init];
    
#if __has_include(<Nyxian-Swift.h>)
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
#endif
    
    return self;
}

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
{
#if __has_include(<Nyxian-Swift.h>)
    if([[LDEProcessManager shared] isExecutingProcessWithBundleIdentifier:bundleIdentifier]) return nil;
    LDEApplicationObject *applicationObject = [[LDEApplicationWorkspace shared] applicationObjectForBundleID:bundleIdentifier];
    if(!applicationObject.isLaunchAllowed)
    {
        [NotificationServer NotifyUserWithLevel:NotifLevelError notification:[NSString stringWithFormat:@"\"%@\" Is No Longer Available", applicationObject.displayName] delay:0.0];
        return nil;
    }
    
    self = [self initWithPath:applicationObject.executablePath withArguments:@[applicationObject.executablePath] withEnvironmentVariables:@{@"HOME": applicationObject.containerPath}];
    
    return self;
#else
    return [self init];
#endif
}

- (instancetype)initWithPath:(NSString*)binaryPath
               withArguments:(NSArray *)arguments
    withEnvironmentVariables:(NSDictionary*)environment
{
#if __has_include(<Nyxian-Swift.h>)
    self = [self initWithItems:@{
        @"endpoint": [ServerDelegate getEndpoint],
        @"mode": @"spawn",
        @"executablePath": binaryPath,
        @"arguments": arguments,
        @"environment": environment
    }];
    
    self.displayName = [[NSURL fileURLWithPath:binaryPath] lastPathComponent];
    self.executablePath = binaryPath;
    
    return self;
#else
    return [self init];
#endif
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

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:self.displayName forKey:@"displayName"];
    [coder encodeObject:self.bundleIdentifier forKey:@"bundleIdentifier"];
    [coder encodeObject:self.executablePath forKey:@"executablePath"];
    [coder encodeObject:self.icon forKey:@"icon"];
    [coder encodeObject:@(self.pid) forKey:@"pid"];
    [coder encodeObject:@(self.uid) forKey:@"uid"];
    [coder encodeObject:@(self.gid) forKey:@"gid"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    if(self = [super init])
    {
        _displayName = [coder decodeObjectOfClass:[NSString class] forKey:@"displayName"];
        _bundleIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:@"bundleIdentifier"];
        _executablePath = [coder decodeObjectOfClass:[NSString class] forKey:@"executablePath"];
        _icon = [coder decodeObjectOfClass:[UIImage class] forKey:@"icon"];
        _pid = ((NSNumber*)[coder decodeObjectOfClass:[NSNumber class] forKey:@"pid"]).intValue;
        _uid = ((NSNumber*)[coder decodeObjectOfClass:[NSNumber class] forKey:@"uid"]).intValue;
        _gid = ((NSNumber*)[coder decodeObjectOfClass:[NSNumber class] forKey:@"gid"]).intValue;
    }
    return self;
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
{
    LDEProcess *process = [[LDEProcess alloc] initWithBundleIdentifier:bundleIdentifier];
    if(!process) return 0;
    pid_t pid = process.pid;
    [self.processes setObject:process forKey:@(pid)];
    return pid;
}

- (pid_t)spawnProcessWithPath:(NSString*)binaryPath
                withArguments:(NSArray *)arguments
     withEnvironmentVariables:(NSDictionary*)environment
{
    LDEProcess *process = [[LDEProcess alloc] initWithPath:binaryPath withArguments:arguments withEnvironmentVariables:environment];
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
#if __has_include(<Nyxian-Swift.h>)
    [[LDEMultitaskManager shared] closeWindowForProcessIdentifier:pid];
#endif
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
