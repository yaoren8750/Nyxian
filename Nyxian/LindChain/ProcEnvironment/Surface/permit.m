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

#import <LindChain/ProcEnvironment/Surface/permit.h>

BOOL permitive_over_process_allowed(pid_t callerPid,
                                    pid_t targetPid)
{
    // Get the objects of both pids
    kinfo_info_surface_t callerObj = proc_object_for_pid(callerPid);
    kinfo_info_surface_t targetObj = proc_object_for_pid(targetPid);
    
    return (callerObj.real.kp_eproc.e_ucred.cr_uid <= targetObj.real.kp_eproc.e_ucred.cr_uid);
}
