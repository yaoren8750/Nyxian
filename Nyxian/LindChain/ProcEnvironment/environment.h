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

/* ----------------------------------------------------------------------
 *  Apple API Headers
 * -------------------------------------------------------------------- */
#import <Foundation/Foundation.h>

/* ----------------------------------------------------------------------
 *  Environment API Headers
 * -------------------------------------------------------------------- */
#import <LindChain/ProcEnvironment/proxy.h>
#import <LindChain/ProcEnvironment/tfp.h>
#import <LindChain/ProcEnvironment/libproc.h>
#import <LindChain/ProcEnvironment/application.h>
#import <LindChain/ProcEnvironment/posix_spawn.h>
#import <LindChain/ProcEnvironment/sysctl.h>
#import <LindChain/ProcEnvironment/fork.h>
#import <LindChain/ProcEnvironment/tfp_object.h>
#import <LindChain/ProcEnvironment/fd_map_object.h>
#import <LindChain/ProcEnvironment/Surface/surface.h>
#import <LindChain/ProcEnvironment/Surface/proc.h>

/*!
 @enum EnvironmentRole
 @abstract Defines the role of the current environment.
 @constant EnvironmentRoleNone
     No environment role is set.
 @constant EnvironmentRoleHost
     The environment is running as the host.
 @constant EnvironmentRoleGuest
     The environment is running as a guest.
 */
typedef NS_ENUM(NSInteger, EnvironmentRole) {
    EnvironmentRoleNone  = 0,
    EnvironmentRoleHost  = 1,
    EnvironmentRoleGuest = 2
};

/*!
 @enum EnvironmentRestriction
 @abstract Defines the restriction of the current environment.
 @constant EnvironmentRestrictionNone
     No environment restriction is set.
 @constant EnvironmentRestrictionSystem
     The environment is running with system restrictions.
 @constant EnvironmentRestrictionUser
     The environment with user restrictions.
 */
typedef NS_ENUM(NSInteger, EnvironmentRestriction) {
    EnvironmentRestrictionNone   = 0, /* Nothing */
    EnvironmentRestrictionUser   = 1, /* Level 1 */
    EnvironmentRestrictionSystem = 2, /* Level 2 */
    EnvironmentRestrictionKernel = 3  /* Level 3: Highest permitives */
};

/*!
 @function environment_client_connect_to_host
 @abstract Connects the client to the host environment using a preshipped endpoint.
 @discussion
    This function establishes a connection between a guest process and
    its host environment. The provided endpoint must have been exported
    by the host.

 @param endpoint
    An `NSXPCListenerEndpoint` object identifying the host environment.
 */
void environment_client_connect_to_host(NSXPCListenerEndpoint *endpoint);

/*!
 @function environment_client_attach_debugger
 @abstract Attaches a debugger to the guest environment
 @discussion
    This function attaches a mach exception handling debugger to the guest environment.
 */
void environment_client_attach_debugger(void);

/*!
 @function environment_is_role
 @abstract Returns a boolean value representing if it is the given role
 @discussion
    This function is used by the modular environment API subsystems to check if certain implementations are applied to the correct role.
 
 @param role
    An `EnvironmentRole` enum value that is the value that must match the internal `EnvironmentRole` enum value for it to succeed
 */
BOOL environment_is_role(EnvironmentRole role);

/*!
 @function environment_must_be_role
 @abstract Returns a boolean value representing if it is the given role and crashes the process if its not.
 @discussion
    This function is used by the modular environment API subsystems to check if certain implementations are applied to the correct role, and exit from irreversible issues due to that.
 
 @param role
    An `EnvironmentRole` enum value that is the value that must match the internal `EnvironmentRole` enum value for it to succeed
 */
BOOL environment_must_be_role(EnvironmentRole role);

/*!
 @function environment_has_restriction_level
 @abstract Returns a boolean value representing if it is the given or higher restriction level.
 @discussion
    This function is used by the modular environment API to decide what to allow and what not.
 
 @param restriction
    An `EnvironmentRestriction` enum value that is the value that must match or be higher than the internal `EnvironmentRestriction` enum value for it to succeed
 */
BOOL environment_has_restriction_level(EnvironmentRestriction restriction);

/*!
 @function environment_ugid
 @abstract Returns a user identifier based on the environments restriction level
 @discussion
    This function is used by the modular environment API to decide what to allow and what not.
 */
uid_t environment_ugid(void);

/*!
 @function environment_init
 @abstract Initializes the environment with a given role.
 @discussion
    This function initializes the environment with the given role. It can and shall only be called once. This function never returns NO!
 
 @param role
    An `EnvironmentRole` enum value that represents the environment role wished to be initializes as.
 @param executablePath
    An character buffer that represents the executable path
 */
void environment_init(EnvironmentRole role, EnvironmentRestriction restriction, const char *executablePath);

#endif /* PROCENVIRONMENT_ENVIRONMENT_H */
