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
#import <LindChain/Debugger/MachServer.h>

PEEntitlement exposed_entitlement = PEEntitlementNone;
static EnvironmentRole environmentRole = EnvironmentRoleNone;
static EnvironmentRestriction environmentRestriction = EnvironmentRestrictionNone;

#pragma mark - Special client extra symbols

void environment_client_connect_to_host(NSXPCListenerEndpoint *endpoint)
{
    // FIXME: We cannot check the environment if the environment is not setup yet
    if(hostProcessProxy) return;
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
    environment_must_be_role(EnvironmentRoleGuest);
    machServerInit();
}

#pragma mark - Role/Restriction checkers and enforcers

BOOL environment_is_role(EnvironmentRole role)
{
    return (environmentRole == role);
}

BOOL environment_must_be_role(EnvironmentRole role)
{
    if(!environment_is_role(role))
        abort();
    else
        return YES;
}

BOOL environment_has_restriction_level(EnvironmentRestriction restriction)
{
    return (environmentRestriction >= restriction);
}

uid_t environment_ugid(void)
{
    uid_t uid = 501;
    if(environment_has_restriction_level(EnvironmentRestrictionSystem))
    {
        uid = 0;
    }
    return uid;
}

#pragma mark - Initilizer

void environment_init(PEEntitlement entitlement,
                      EnvironmentRole role,
                      EnvironmentRestriction restriction,
                      const char *executablePath,
                      pid_t ppid)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Setting entitlement
        exposed_entitlement = entitlement;
        
        // Setting environment properties
        environmentRole = role;
        environmentRestriction = restriction;
        
        // We do proc_surface_init() before environment_tfp_init(), because otherwise a other process could get the task port of this process and suspend it and abuse its NSXPCConnection to gather write access to the proc surface
        proc_surface_init(ppid, executablePath);
        
        environment_tfp_init();
        environment_libproc_init();
        environment_application_init();
        environment_posix_spawn_init();
        environment_fork_init();
        environment_sysctl_init();
    });
}
