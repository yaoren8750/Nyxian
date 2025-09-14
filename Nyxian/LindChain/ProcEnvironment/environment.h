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

#ifndef PROCENVIRONMENT_ENVIRONMENT_H
#define PROCENVIRONMENT_ENVIRONMENT_H

#import <Foundation/Foundation.h>
#import <LindChain/ProcEnvironment/Server/ServerProtocol.h>

/// Boolean value that indicates if the target environment runs at is the host or the guest environment at runtime
extern BOOL environmentIsHost;

/// Connects client to host environment via its preshipped endpoint
void environment_client_connect_to_host(NSXPCListenerEndpoint *endpoint);

/// Hands off clients standard file descriptors to host environment so output gets redirected to host environment
void environment_client_handoff_standard_file_descriptors(void);

/// Attaches debugger to the guest environment it self, its a self debugger
void environment_client_attach_debugger(void);

/// Initilizes the environment, the boolean argument the symbol takes indicates if its the host or the client environment
void environment_init(BOOL host);

#endif /* PROCENVIRONMENT_ENVIRONMENT_H */
