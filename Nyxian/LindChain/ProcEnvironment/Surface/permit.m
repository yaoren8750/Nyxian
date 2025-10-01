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
#import <LindChain/ProcEnvironment/Surface/permit.h>
#import <LindChain/ProcEnvironment/Surface/entitlement.h>

BOOL permitive_over_process_allowed(pid_t callerPid,
                                    pid_t targetPid)
{
    // Only let host proceed
    environment_must_be_role(EnvironmentRoleHost);
    
    // Get the objects of both pids
    kinfo_info_surface_t callerObj = proc_object_for_pid(callerPid);
    kinfo_info_surface_t targetObj = proc_object_for_pid(targetPid);
    
    // Gets creds
    uid_t caller_uid = proc_getuid(callerObj);
    
    // Gets if its allowed in the first place
    if((caller_uid == 0) ||
       (caller_uid == proc_getuid(targetObj)) ||
       (caller_uid == proc_getruid(targetObj))) return YES;
    
    // Check if process has `PEEntitlementChildSupervisor`
    if(!entitlement_got_entitlement(proc_getentitlements(callerObj), PEEntitlementChildSupervisor)) return NO;
    
    // Since it got `PEEntitlementChildSupervisor`, we need to walk in the process tree
    pid_t kern_pid = getpid();
    while(1)
    {
        // Get ppid of target pid
        targetObj = proc_object_for_pid(targetPid);
        
        // Get ppid
        pid_t ppid = proc_getppid(targetObj);
        
        // In case ppid is kern_pid it is automatically a NO and if ppid is callerPid then its a yes because thats power over child process tree as a parent in the tree
        if(ppid == 0 || ppid == kern_pid)
            return NO;
        else if(ppid == callerPid)
            return YES;
        
        // This time not so we set targetPid to ppid
        targetPid = ppid;
    }
    
    return NO;
}
