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

// MARK: The craziest thing to prove my skill level ever

#import <LindChain/ProcEnvironment/environment.h>
#import <LindChain/ProcEnvironment/proxy.h>
#import <LindChain/ProcEnvironment/tfp.h>
#include <mach/mach.h>

/*
 Host version of fork() so fork() of child can ask the server to perform a fork()
 
 having 0 as return value means that it failed here
 */
pid_t environment_fork_for_pid(pid_t requestor_process_identifier)
{
    if(environmentIsHost)
    {
        // MARK: Okay so now executing a task, huh?
        // MARK: We just need to get our hands onto a task right that belongs to no process the user needs, a brand new one
        // MARK: We also need the task right of the process requesting
        // MARK: We then suspend both processes(requesting and the one at fork stage) and then clear the entire task at fork stage and copy over vm map and thread states over
        // MARK: Mammut task
        // MARK: Page allignment will probably kill me
        
        // Get the requestors task port (iOS 26 only)
        mach_port_t requestor_task_port = MACH_PORT_NULL;
        kern_return_t kr = environment_task_for_pid(mach_task_self(), requestor_process_identifier, &requestor_task_port);
        if(kr != KERN_SUCCESS) return 0;
        
        // Create forked process
        __block pid_t forked_process_identifier = 0;
        [hostProcessProxy createForkingStageProcessViaReply:^(pid_t fork_pid){
            forked_process_identifier = fork_pid;
            dispatch_semaphore_signal(environment_semaphore);
        }];
        dispatch_semaphore_wait(environment_semaphore, DISPATCH_TIME_FOREVER);
        
        // Get the forked task port (iOS 26 only)
        mach_port_t forked_task_port = MACH_PORT_NULL;
        kr = environment_task_for_pid(mach_task_self(), forked_process_identifier, &forked_task_port);
        if(kr != KERN_SUCCESS) return 0;
        
        // Since we have both now, suspend both
        task_suspend(requestor_task_port);
        task_suspend(forked_task_port);
        
        // Now we can perform the forking
    }
    return 0;
}
