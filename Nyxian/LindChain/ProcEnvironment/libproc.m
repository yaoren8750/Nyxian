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
#import <LindChain/Multitask/LDEProcessManager.h>

/*
 Helper function
 */
LDEProcess *environment_client_get_process_of_process_identifier(pid_t process_identifier)
{
    if(environmentIsHost) return nil;
    __block LDEProcess *process = nil;
    [hostProcessProxy proc_getProcStructureForProcessIdentifier:process_identifier withReply:^(LDEProcess *replyProcess){
        process = replyProcess;
        dispatch_semaphore_signal(environment_semaphore);
    }];
    dispatch_semaphore_wait(environment_semaphore, DISPATCH_TIME_FOREVER);
    return process;
}

/*
 Actual API override
 */
int environment_proc_listallpids(void *buffer,
                                 int buffersize)
{
    if(!environmentIsHost)
    {
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
    }
    return 0;
}

int environment_proc_name(int pid,
                          void * buffer,
                          uint32_t buffersize)
{
    if(!environmentIsHost)
    {
        // MARK: GUEST
        // Take process structure of requested process identifier
        LDEProcess *process = environment_client_get_process_of_process_identifier(pid);
        if(!process) return 0;
        
        // Now overwrite get c str of proc name
        const char *c_str = process.displayName.UTF8String;
        
        // Now check if size is enough
        size_t copied = (strlen(c_str) < buffersize) ? strlen(c_str) : buffersize;
        strncpy(buffer, c_str, buffersize);
        return (int)copied;
    }
    return 0;
}

int environment_proc_pidpath(int pid,
                             void *buffer,
                             uint32_t buffersize)
{
    if(!environmentIsHost)
    {
        // MARK: GUEST
        // Take process structure of requested process identifier
        LDEProcess *process = environment_client_get_process_of_process_identifier(pid);
        if(!process) return 0;
        
        // Now overwrite get c str of proc name
        const char *c_str = process.executablePath.UTF8String;
        
        // Now check if size is enough
        if (!c_str) {
            c_str = "/unknown/path/to/binary";
        }
        
        size_t copied = (strlen(c_str) < buffersize) ? strlen(c_str) : buffersize;
        strncpy(buffer, c_str, buffersize);
        return (int)copied;
    }
    return 0;
}

int environment_kill(pid_t pid, int signal)
{
    if(!environmentIsHost)
    {
        // MARK: GUEST
        // Take process structure of requested process identifier
        __block int result = 1;
        [hostProcessProxy proc_kill:pid withSignal:signal withReply:^(int replyResult){
            result = replyResult;
            dispatch_semaphore_signal(environment_semaphore);
        }];
        dispatch_semaphore_wait(environment_semaphore, DISPATCH_TIME_FOREVER);
        
        return result;
    }
    return 1;
}

/*
 Init
 */
void environment_libproc_init(BOOL host)
{
    if(!host)
    {
        // MARK: GUEST Init
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, proc_listallpids, environment_proc_listallpids, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, proc_name, environment_proc_name, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, proc_pidpath, environment_proc_pidpath, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, kill, environment_kill, nil);
    }
}
