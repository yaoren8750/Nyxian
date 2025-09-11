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
#import <LindChain/ProcEnvironment/libproc_userspace.h>
#import <LindChain/litehook/src/litehook.h>
#import <LindChain/LiveContainer/Tweaks/libproc.h>

#if HOST_ENV
#import <LindChain/Multitask/LDEProcessManager.h>
#endif

/*
 Actual API override
 */
int environment_proc_listallpids(void *buffer,
                                 int buffersize)
{
#if HOST_ENV
    // MARK: HOST Implementation
    // Cast to pid array
    pid_t *array = (pid_t*)buffer;
    
    // Calculate the amount of slices that fit into the array first
    size_t count = buffersize / sizeof(pid_t);
    size_t hounter = 0;
    
    // Now itterate, and remove each cycle a slice
    for(NSNumber *number in [[LDEProcessManager shared] processes])
    {
        // Copy them to buffer
        array[hounter] = number.intValue;
        hounter++;
        if(hounter == count) return (int)(hounter * sizeof(pid_t));
    }
    
    return (int)(hounter * sizeof(pid_t));
#else
    // MARK: GUEST Implementation
    // Cast to pid array
    pid_t *array = (pid_t*)buffer;
    
    // Calculate the amount of slices that fit into the array first
    size_t count = buffersize / sizeof(pid_t);
    size_t hounter = 0;
    
    // Get pids from server
    __block NSMutableSet<NSNumber*> *environment_process_identifier;
    [hostProcessProxy proc_listallpidsViaReply:^(NSSet *processes){
        environment_process_identifier = [NSMutableSet setWithSet:processes];
        dispatch_semaphore_signal(environment_semaphore);
    }];
    dispatch_semaphore_wait(environment_semaphore, DISPATCH_TIME_FOREVER);
    
    // Now itterate, and remove each cycle a slice
    for(NSNumber *number in environment_process_identifier)
    {
        // Copy them to buffer
        array[hounter] = number.intValue;
        hounter++;
        if(hounter == count) return (int)(hounter * sizeof(pid_t));
    }
    return (int)(hounter * sizeof(pid_t));
#endif
}



/*
 Init
 */
void environment_libproc_userspace_init(BOOL host)
{
    if(!host)
    {
        // MARK: GUEST Init
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, proc_listallpids, environment_proc_listallpids, nil);
    }
}
