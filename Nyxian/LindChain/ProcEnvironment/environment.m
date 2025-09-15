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
#import <LindChain/ProcEnvironment/proxy.h>
#import <LindChain/Debugger/MachServer.h>

#import <LindChain/ProcEnvironment/tfp.h>
#import <LindChain/ProcEnvironment/libproc.h>
#import <LindChain/ProcEnvironment/application.h>
#import <LindChain/ProcEnvironment/posix_spawn.h>
#import <LindChain/ProcEnvironment/sysctl.h>

BOOL environmentIsHost;

void environment_init(BOOL host)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        environment_tfp_init(host);
        environment_libproc_init(host);
        environment_application_init(host);
        environment_posix_spawn_init(host);
        environment_sysctl_init(host);
        environmentIsHost = host;
    });
}

void environment_client_connect_to_host(NSXPCListenerEndpoint *endpoint)
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
    hostProcessProxy = connection.remoteObjectProxy;
}

void environment_client_attach_debugger(void)
{
    if(environmentIsHost) return;
    machServerInit();
}
