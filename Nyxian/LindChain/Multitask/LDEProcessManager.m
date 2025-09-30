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
#import <LindChain/ProcEnvironment/Server/Server.h>
#import <LindChain/ProcEnvironment/Surface/surface.h>
#import <LindChain/ProcEnvironment/Surface/proc.h>
#import <LindChain/ProcEnvironment/Server/Trust.h>

@implementation LDEProcessConfiguration

- (instancetype)initWithParentProcessIdentifier:(pid_t)ppid
                             withUserIdentifier:(uid_t)uid
                            withGroupIdentifier:(gid_t)gid
                               withEntitlements:(PEEntitlement)entitlements
{
    self = [super init];
    
    self.ppid = ppid;
    self.uid = uid;
    self.gid = gid;
    self.entitlements = entitlements;
    
    return self;
}

+ (instancetype)inheriteConfigurationUsingProcessIdentifier:(pid_t)pid
{
    kinfo_info_surface_t object = proc_object_for_pid(pid);
    return [[self alloc] initWithParentProcessIdentifier:object.real.kp_proc.p_pid withUserIdentifier:object.real.kp_eproc.e_pcred.p_ruid withGroupIdentifier:object.real.kp_eproc.e_pcred.p_rgid withEntitlements:object.entitlements];
}

+ (instancetype)userApplicationConfiguration
{
    return [[self alloc] initWithParentProcessIdentifier:getpid() withUserIdentifier:501 withGroupIdentifier:501 withEntitlements:PEEntitlementDefaultUserApplication];
}

+ (instancetype)systemApplicationConfiguration
{
    return [[self alloc] initWithParentProcessIdentifier:getpid() withUserIdentifier:501 withGroupIdentifier:501 withEntitlements:PEEntitlementDefaultSystemApplication];
}

+ (instancetype)configurationForHash:(NSString*)hash
{
    return [[self alloc] initWithParentProcessIdentifier:getpid() withUserIdentifier:501 withGroupIdentifier:501 withEntitlements:[[TrustCache shared] getEntitlementsForHash:hash]];
}

@end

/*
 Process
 */
@implementation LDEProcess

- (instancetype)initWithItems:(NSDictionary*)items
            withConfiguration:(LDEProcessConfiguration*)configuration
{
    self = [super init];
    
    if(!proc_can_spawn()) return nil;
    
    self.displayName = @"LiveProcess";
    self.executablePath = items[@"LSExecutablePath"];
    if(self.executablePath == nil) return nil;
    else self.displayName = [[NSURL fileURLWithPath:self.executablePath] lastPathComponent];
    
    self.ppid = configuration.ppid;
    self.uid = configuration.uid;
    self.gid = configuration.gid;
    
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
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [_extension beginExtensionRequestWithInputItems:@[item] completion:^(NSUUID *identifier) {
        if(identifier) {
            if(weakSelf == nil) return;
            __typeof(self) strongSelf = weakSelf;
            
            weakSelf.identifier = identifier;
            weakSelf.pid = [self.extension pidForRequestIdentifier:self.identifier];
            RBSProcessPredicate* predicate = [PrivClass(RBSProcessPredicate) predicateMatchingIdentifier:@(weakSelf.pid)];
            weakSelf.processMonitor = [PrivClass(RBSProcessMonitor) monitorWithPredicate:predicate updateHandler:^(RBSProcessMonitor *monitor,
                                                                                                                   RBSProcessHandle *handle,
                                                                                                                   RBSProcessStateUpdate *update)
                                       {
                // Setting process handle directly from process monitor
                weakSelf.processHandle = handle;
                proc_create_child_proc(strongSelf.ppid, strongSelf.pid, strongSelf.uid, strongSelf.gid, strongSelf.executablePath, configuration.entitlements);
                
                // Interestingly, when a process exits, the process monitor says that there is no state, so we can use that as a logic check
                NSArray<RBSProcessState *> *states = [monitor states];
                if([states count] == 0)
                {
                    // Process dead!
                    dispatch_once(&strongSelf->_removeOnce, ^{
                        proc_object_remove_for_pid(strongSelf.pid);
                        [[LDEMultitaskManager shared] closeWindowForProcessIdentifier:strongSelf.pid];
                        [[LDEProcessManager shared] unregisterProcessWithProcessIdentifier:strongSelf.pid];
                    });
                }
            }];
        }
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return self;
}

- (instancetype)initWithPath:(NSString*)binaryPath
               withArguments:(NSArray *)arguments
    withEnvironmentVariables:(NSDictionary*)environment
               withMapObject:(FDMapObject*)mapObject
           withConfiguration:(LDEProcessConfiguration*)configuration
{
    self = [self initWithItems:@{
        @"LSEndpoint": [Server getTicket],
        @"LSServiceMode": @"spawn",
        @"LSExecutablePath": binaryPath,
        @"LSArguments": arguments,
        @"LSEnvironment": environment,
        @"LSMapObject": mapObject
    } withConfiguration:configuration];
    
    return self;
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

- (void)setRequestCancellationBlock:(void(^)(NSUUID *uuid, NSError *error))callback
{
    [_extension setRequestCancellationBlock:callback];
}

- (void)setRequestInterruptionBlock:(void(^)(NSUUID *uuid))callback
{
    [_extension setRequestInterruptionBlock:callback];
}

@end

/*
 Process Manager
 */
@implementation LDEProcessManager {
    NSTimeInterval _lastSpawnTime;
    NSTimeInterval _spawnCooldown;
}

- (instancetype)init
{
    self = [super init];
    self.processes = [[NSMutableDictionary alloc] init];
    
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    _spawnCooldown = (100ull * timebase.denom) / timebase.numer;
    _lastSpawnTime = 0;
    
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

- (void)enforceSpawnCooldown
{
    uint64_t now = mach_absolute_time();
    uint64_t elapsed = now - _lastSpawnTime;

    if(elapsed < _spawnCooldown)
    {
        uint64_t waitTicks = _spawnCooldown - elapsed;
        
        mach_timebase_info_data_t timebase;
        mach_timebase_info(&timebase);
        uint64_t nsToWait = waitTicks * timebase.numer / timebase.denom;

        struct timespec ts;
        ts.tv_sec = (time_t)(nsToWait / 1000000000ull);
        ts.tv_nsec = (long)(nsToWait % 1000000000ull);
        nanosleep(&ts, NULL);
    }

    _lastSpawnTime = mach_absolute_time();
}

- (pid_t)spawnProcessWithItems:(NSDictionary*)items
             withConfiguration:(LDEProcessConfiguration*)configuration
{
    [self enforceSpawnCooldown];
    
    LDEProcess *process = [[LDEProcess alloc] initWithItems:items withConfiguration:configuration];
    if(!process) return 0;
    pid_t pid = process.pid;
    [self.processes setObject:process forKey:@(pid)];
    return pid;
}

- (pid_t)spawnProcessWithBundleIdentifier:(NSString *)bundleIdentifier
                        withConfiguration:(LDEProcessConfiguration*)configuration
                       doRestartIfRunning:(BOOL)doRestartIfRunning
{
    LDEApplicationObject *applicationObject = [[LDEApplicationWorkspace shared] applicationObjectForBundleID:bundleIdentifier];
    if(!applicationObject.isLaunchAllowed)
    {
        [NotificationServer NotifyUserWithLevel:NotifLevelError notification:[NSString stringWithFormat:@"\"%@\" Is No Longer Available", applicationObject.displayName] delay:0.0];
        return 0;
    }
    
    [self enforceSpawnCooldown];
    
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
    
    FDMapObject *mapObject = [FDMapObject currentMap];
    
    LDEProcess *process = nil;
    pid_t pid = [self spawnProcessWithPath:applicationObject.executablePath withArguments:@[applicationObject.executablePath] withEnvironmentVariables:@{
        @"HOME": applicationObject.containerPath
    } withMapObject:mapObject withConfiguration:configuration process:&process];
    process.bundleIdentifier = applicationObject.bundleIdentifier;
    return pid;
}

- (pid_t)spawnProcessWithBundleIdentifier:(NSString *)bundleIdentifier
                        withConfiguration:(LDEProcessConfiguration*)configuration
{
    return [self spawnProcessWithBundleIdentifier:bundleIdentifier withConfiguration:configuration doRestartIfRunning:NO];
}

- (pid_t)spawnProcessWithPath:(NSString*)binaryPath
                withArguments:(NSArray *)arguments
     withEnvironmentVariables:(NSDictionary*)environment
                withMapObject:(FDMapObject*)mapObject
            withConfiguration:(LDEProcessConfiguration*)configuration
                      process:(LDEProcess**)processReply
{
    [self enforceSpawnCooldown];
    LDEProcess *process = [[LDEProcess alloc] initWithPath:binaryPath withArguments:arguments withEnvironmentVariables:environment withMapObject:mapObject withConfiguration:configuration];
    if(!process) return 0;
    pid_t pid = process.pid;
    [self.processes setObject:process forKey:@(pid)];
    if(processReply) *processReply = process;
    return pid;
}

- (void)closeIfRunningUsingBundleIdentifier:(NSString*)bundleIdentifier
{
    for(NSNumber *key in self.processes)
    {
        LDEProcess *process = self.processes[key];
        if(!process || ![process.bundleIdentifier isEqualToString:bundleIdentifier]) continue;
        else
        {
            [process terminate];
        }
    }
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
