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

extern BOOL environmentIsHost;
extern dispatch_semaphore_t environment_semaphore;

void environment_client_connect_to_host(NSXPCListenerEndpoint *endpoint);
void environment_client_handoff_standard_file_descriptors(void);
void environment_client_attach_debugger(void);

void environment_init(BOOL host);

#endif /* PROCENVIRONMENT_ENVIRONMENT_H */
