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

#ifndef PROCENVIRONMENT_PROXY_H
#define PROCENVIRONMENT_PROXY_H

/* ----------------------------------------------------------------------
 *  Apple API Headers
 * -------------------------------------------------------------------- */
#import <Foundation/Foundation.h>

/* ----------------------------------------------------------------------
 *  Environment API Headers
 * -------------------------------------------------------------------- */
#import <LindChain/ProcEnvironment/Server/ServerProtocol.h>

// Applicable for child process
extern NSObject<ServerProtocol> *hostProcessProxy;

// MARK: Helper symbols that are intended stabilizing the proc environment api proxy wise and reduce the amount of deadlocking in the future

/// Sets the endpoint of applicationmgmtd in the host application, so it can manage applications and such
void environment_proxy_set_ldeapplicationworkspace_endpoint(NSXPCListenerEndpoint *endpoint);

/// Sends a task port to the host application to hand it to other requesting processes
void environment_proxy_tfp_send_port_object(MachPortObject *port) API_AVAILABLE(ios(26.0));

/// Get a task port from the host application that a other process has handed in using `environment_proxy_tfp_send_port_object(TaskPortObject *port)`
MachPortObject *environment_proxy_tfp_get_port_object_for_process_identifier(pid_t process_identifier) API_AVAILABLE(ios(26.0));

/// Gets the list of all process identifiers running
NSSet *environment_proxy_proc_list_all_process_identifier(void);

/// Gets the process structure of a particular process identifier
LDEProcess *environment_proxy_proc_structure_for_process_identifier(pid_t process_identifier);

/// Sends the `signal` to the process identified by its `process_identifier`
int environment_proxy_proc_kill_process_identifier(pid_t process_identifier, int signal);

/// Asks the host application to make your process visible via a window, similar to macOS
BOOL environment_proxy_make_window_visible(void);

/// Spawns a process using a binary at `path` with `arguments` and `environment` and posix like `file_actions`
pid_t environment_proxy_spawn_process_at_path(NSString *path, NSArray *arguments, NSDictionary *environment, FDMapObject *mapObject);

/// Gathers code signature information from the host application environment
void environment_proxy_gather_code_signature_info(NSData **certificateData, NSString **certificatePassword);

/// Gathers bundle path of host application environment
NSString *environment_proxy_gather_code_signature_extras(void);

/// Returns the proc surfaces handle
void environment_proxy_get_surface_mappings(MappingPortObject **surface, MappingPortObject **safety);

/// Sets user identifier
int environment_proxy_setuid(uid_t uid);

/// Sets group identifier
int environment_proxy_setgid(gid_t gid);

/// Sets effective user identifier
int environment_proxy_seteuid(uid_t uid);

/// Sets effective group identifier
int environment_proxy_setegid(gid_t gid);

/// Sets real user identifier
int environment_proxy_setruid(uid_t uid);

/// Sets real group identifier
int environment_proxy_setrgid(gid_t gid);

#endif /* PROCENVIRONMENT_PROXY_H */
