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
#import <LindChain/LiveProcess/LDEApplicationWorkspace.h>
#import <LindChain/Multitask/LDEMultitaskManager.h>
#import <LindChain/Debugger/Logger.h>
#import <LindChain/LiveContainer/LCUtils.h>
#import <mach/mach.h>

@implementation Server

- (void)getStdoutOfServerViaReply:(void (^)(NSFileHandle *))reply
{
    reply([[NSFileHandle alloc] initWithFileDescriptor:STDOUT_FILENO]);
}

- (void)getMemoryLogFDsForPID:(pid_t)pid
                    withReply:(void (^)(NSFileHandle *))reply
{
    // TODO: Fix for new window api
    /*NSString *bundleIdentifier = [[LDEMultitaskManager shared] bundleIdentifierForProcessIdentifier:pid];
    if(bundleIdentifier)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            LogTextView *textLog = [[LogTextView alloc] init];
            [[LDEMultitaskManager shared] attachView:textLog toWindowGroupOfBundleIdentifier:bundleIdentifier withTitle:@"Log"];
            int fd = textLog.pipe.fileHandleForWriting.fileDescriptor;
            reply([[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:NO]);
        });
    } else {
        reply(nil);
    }*/
}

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
        [[LDEApplicationWorkspace shared] setProxy:[connection remoteObjectProxy]];
    }
}

/*
 tfp_userspace
 */
- (void)sendPort:(TaskPortObject*)machPort
{
    environment_host_take_client_task_port(machPort);
}

- (void)getPort:(pid_t)pid
      withReply:(void (^)(TaskPortObject*))reply
{
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
    // If pid is 0 raise the signal on our selves
    if(pid == 0) raise(signal);
    else
    {
        
        // Other target, lets look for it!
        LDEProcess *process = [[LDEProcessManager shared] processForProcessIdentifier:pid];
        if(!process)
        {
            reply(1);
            return;
        }
        
        [process.extension _kill:signal];
    }
    
    reply(0);
}

/*
 application
 */
- (void)makeWindowVisibleForProcessIdentifier:(pid_t)processIdentifier withReply:(void (^)(BOOL))reply
{
    // To be done
    reply([[LDEMultitaskManager shared] openWindowForProcessIdentifier:processIdentifier]);
}

/*
 posix_spawn
 */
- (void)spawnProcessWithPath:(NSString*)path withArguments:(NSArray*)arguments withEnvironmentVariables:(NSDictionary *)environment withReply:(void (^)(pid_t))reply
{
    reply([[LDEProcessManager shared] spawnProcessWithPath:path withArguments:arguments withEnvironmentVariables:environment]);
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

@end
