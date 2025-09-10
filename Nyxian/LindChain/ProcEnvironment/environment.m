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

#import <LindChain/ProcEnvironment/environment.h>
#import <LindChain/ProcEnvironment/tfp_userspace.h>
#import <LindChain/ProcEnvironment/proxy.h>
#import <LindChain/Debugger/MachServer.h>

BOOL environmentIsHost;
dispatch_semaphore_t environment_semaphore;

void environment_init(BOOL host)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        environment_tfp_userspace_init(host);
        if(!host) environment_semaphore = dispatch_semaphore_create(0);
        environmentIsHost = host;
    });
}

void environment_client_handoff_proxy(NSObject<ServerProtocol> *proxy)
{
    if(environmentIsHost || hostProcessProxy) return;
    hostProcessProxy = proxy;
}

void environment_client_connect(NSXPCListenerEndpoint *endpoint)
{
    if(environmentIsHost || hostProcessProxy) return;
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithListenerEndpoint:endpoint];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ServerProtocol)];
    connection.interruptionHandler = ^{
        NSLog(@"Connection to app interrupted");
        exit(0);
    };
    connection.invalidationHandler = ^{
        NSLog(@"Connection to app invalidated");
        exit(0);
    };
    
    [connection activate];
    environment_client_handoff_proxy([connection remoteObjectProxy]);
}

void environment_client_attach_debugger(void)
{
    if(environmentIsHost) return;
    machServerInit();
}

void environment_client_handoff_standard_file_descriptors(void)
{
    if(environmentIsHost || !hostProcessProxy) return;
    [hostProcessProxy getStdoutOfServerViaReply:^(NSFileHandle *stdoutHandle){
        dup2(stdoutHandle.fileDescriptor, STDOUT_FILENO);
        dup2(stdoutHandle.fileDescriptor, STDERR_FILENO);
        setvbuf(stdout, NULL, _IONBF, 0);
        setvbuf(stderr, NULL, _IONBF, 0);
        dispatch_semaphore_signal(environment_semaphore);
    }];
    dispatch_semaphore_wait(environment_semaphore, DISPATCH_TIME_FOREVER);
}
