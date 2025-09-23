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

#import <LindChain/ProcEnvironment/Server/Server.h>
#import <LindChain/ProcEnvironment/tfp.h>
#import <LindChain/Services/applicationmgmtd/LDEApplicationWorkspace.h>
#import <LindChain/Multitask/LDEMultitaskManager.h>
#import <LindChain/Debugger/Logger.h>
#import <LindChain/LiveContainer/LCUtils.h>
#import <LindChain/ProcEnvironment/Surface/permit.h>
#import <LindChain/ProcEnvironment/Surface/entitlement.h>
#import <mach/mach.h>

@implementation Server

- (void)setLDEApplicationWorkspaceEndPoint:(NSXPCListenerEndpoint*)endpoint
{
    LDEApplicationWorkspace *workspace = [LDEApplicationWorkspace shared];
    if(workspace.proxy == nil)
    {
        NSXPCConnection* connection = [[NSXPCConnection alloc] initWithListenerEndpoint:endpoint];
        connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LDEApplicationWorkspaceProxyProtocol)];
        connection.interruptionHandler = ^{
            NSLog(@"Connection to LDEApplicationWorkspaceProxy interrupted");
        };
        connection.invalidationHandler = ^{
            NSLog(@"Connection to LDEApplicationWorkspaceProxy invalidated");
        };
        
        [connection activate];
        workspace.proxy = [connection remoteObjectProxy];
    }
}

/*
 tfp_userspace
 */
- (void)sendPort:(TaskPortObject*)machPort API_AVAILABLE(ios(26.0));
{
    environment_host_take_client_task_port(machPort);
}

- (void)getPort:(pid_t)pid
      withReply:(void (^)(TaskPortObject*))reply API_AVAILABLE(ios(26.0));
{
    // Does the process requesting even have the entitlement
    if(!proc_got_entitlement(_processIdentifier, PEEntitlementTaskForPid))
    {
        reply(nil);
        return;
    }
    
    // Special or host
    bool special = proc_got_entitlement(_processIdentifier, PEEntitlementTaskForPidSpecial);
    bool host = proc_got_entitlement(_processIdentifier, PEEntitlementGetHostTaskPort);
    
    // Is the request pid the host app
    if(pid == getpid() && !host)
    {
        reply(nil);
        return;
    }
    
    // Needs special?
    if(!permitive_over_process_allowed(_processIdentifier, pid) && !special)
    {
        reply(nil);
        return;
    }
    
    // Send requested task port
    mach_port_t port;
    kern_return_t kr = environment_task_for_pid(mach_task_self(), pid, &port);
    reply((kr == KERN_SUCCESS) ? [[TaskPortObject alloc] initWithPort:port] : nil);
}

/*
 libproc_userspace
 */
- (void)proc_listallpidsViaReply:(void (^)(NSSet*))reply
{
    reply([NSSet setWithArray:[[LDEProcessManager shared] processes].allKeys]);
}

- (void)proc_getProcStructureForProcessIdentifier:(pid_t)pid withReply:(void (^)(LDEProcess*))reply
{
    reply([[LDEProcessManager shared] processForProcessIdentifier:pid]);
}

- (void)proc_kill:(pid_t)pid withSignal:(int)signal withReply:(void (^)(int))reply
{
    // Other target, lets look for it!
    LDEProcess *process = [[LDEProcessManager shared] processForProcessIdentifier:pid];
    if(!process)
    {
        reply(1);
        return;
    }
    
    [process sendSignal:signal];
    
    reply(0);
}

/*
 application
 */
- (void)makeWindowVisibleWithReply:(void (^)(BOOL))reply
{
    __block BOOL didInvokeWindow = NO;
    dispatch_once(&_makeWindowVisibleOnce,^{
        // To be done
        didInvokeWindow = [[LDEMultitaskManager shared] openWindowForProcessIdentifier:_processIdentifier];
    });
    
    reply(didInvokeWindow);
}

/*
 posix_spawn
 */
- (void)spawnProcessWithPath:(NSString*)path withArguments:(NSArray*)arguments withEnvironmentVariables:(NSDictionary *)environment withMapObject:(FDMapObject*)mapObject withReply:(void (^)(pid_t))reply
{
    reply([[LDEProcessManager shared] spawnProcessWithPath:path withArguments:arguments withEnvironmentVariables:environment withMapObject:mapObject withParentProcessIdentifier:_processIdentifier process:nil]);
}

- (void)assignProcessInfo:(LDEProcess*)process withProcessIdentfier:(pid_t)pid
{
    // Get process
    LDEProcess *targetProcess = [[LDEProcessManager shared] processForProcessIdentifier:pid];
    if(targetProcess)
    {
        targetProcess.executablePath = process.executablePath;
        targetProcess.bundleIdentifier = process.bundleIdentifier;
        targetProcess.displayName = process.displayName;
        targetProcess.icon = process.icon;
    }
}

/*
 Code signer
 */
- (void)gatherCodeSignerViaReply:(void (^)(NSData*,NSString*))reply
{
    reply(LCUtils.certificateData, LCUtils.certificatePassword);
}

- (void)gatherSignerExtrasViaReply:(void (^)(NSString*))reply
{
    reply([[NSBundle mainBundle] bundlePath]);
}

/*
 fork
 */
- (void)createForkingStageProcessViaReply:(void (^)(pid_t))reply
{
    reply([[LDEProcessManager shared] spawnProcessWithItems:@{ @"mode": @"fork" }]);
}

/*
 surface
 */
- (void)handinSurfaceFileDescriptorViaReply:(void (^)(NSFileHandle *, NSFileHandle *))reply
{
    dispatch_once(&_handoffSurfaceOnce, ^{
        reply(proc_surface_handoff(), proc_safety_handoff());
        return;
    });
    
    if(_handoffSurfaceOnce != 0) reply(nil,nil);
}

/*
 Internal
 */
- (void)setProcessIdentifier:(pid_t)processIdentifier
{
    dispatch_once(&_handoffProcessIdentifierOnce, ^{
        _processIdentifier = processIdentifier;
    });
}

/*
 Background mode fixup
 */
- (void)setAudioBackgroundModeActive:(BOOL)active
{
    LDEProcess *process = [[LDEProcessManager shared] processForProcessIdentifier:_processIdentifier];
    if(process)
    {
        process.audioBackgroundModeUsage = active;
    }
}

@end
