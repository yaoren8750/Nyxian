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

/*
 Header
 */
#import <LindChain/ProcEnvironment/environment.h>
#import <LindChain/ProcEnvironment/proxy.h>
#import <LindChain/ProcEnvironment/libproc.h>
#import <LindChain/litehook/src/litehook.h>
#import <LindChain/LiveContainer/Tweaks/libproc.h>

// MARK: The saviour API of Nyxians modern day proc API performance
#import <LindChain/ProcEnvironment/Surface/surface.h>

/*
 Init
 */
void environment_libproc_init(BOOL host)
{
    if(!host)
    {
        // MARK: GUEST Init
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, proc_listallpids, proc_libproc_listallpids, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, proc_name, proc_libproc_name, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, proc_pidpath, proc_libproc_pidpath, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, proc_pidinfo, proc_libproc_pidinfo, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, proc_pid_rusage, proc_libproc_pid_rusage, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, kill, environment_proxy_proc_kill_process_identifier, nil);
    }
}
