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
#import <LindChain/ProcEnvironment/fork.h>
#include <mach/mach.h>
#import <pthread.h>

void* environment_rip_wait(void *arg)
{
    while(1) {}
}

thread_t environment_rip_thread(void)
{
    // Letting libc API create a thread for us to then rip the valid thread (Safes ton of time)
    pthread_t pthread;
    pthread_create(&pthread, NULL, environment_rip_wait, NULL);
    thread_t thread = pthread_mach_thread_np(pthread);
    thread_suspend(thread);
    return thread;
}

void environment_thread_copy_stack(thread_t dest,
                                   thread_t src,
                                   size_t size)
{
    // Symbol copies stack over with a givven size
    arm_thread_state64_t dest_state, src_state;
    
    // Get the thread state
    
}

void* environment_thread_dup(void *args)
{
    // Give `environment_fork()` time to suspend its own thread
    usleep(100);
    
    // MARK: Target Thread
    // Now get the transmitted thread port
    thread_t thread = *((thread_t*)args);
    
    // Now get the current thread state
    arm_thread_state64_t state;
    mach_msg_type_number_t number = ARM_THREAD_STATE64_COUNT;
    thread_get_state(thread, ARM_THREAD_STATE64, (thread_state_t)&state, &number);
    
    // MARK: Child Thread
    // Now we have the state, now we create a new thread
    thread_t duplicatedThread = environment_rip_thread();
    
    // Now set the thread state
    thread_set_state(duplicatedThread, ARM_THREAD_STATE64, (thread_state_t)&state, number);
    
    // We still cannot just let both run, we have to create a new stack memory
    
    return NULL;
}

void environment_fork(void)
{
    // MARK: Things are fork has to keep the same process keep spinning, no fork, usually fork is used in combination with execl and execvp so we copy the callers thread
    
    // Allocating memory for thread port
    thread_t *thread = malloc(sizeof(thread_t));
    
    // Inserting own thread
    *thread = mach_thread_self();
    
    // Now creating pthread
    pthread_t pthread;
    pthread_create(&pthread, NULL, environment_thread_dup, thread);
    pthread_detach(pthread);
    
    // Suspend our selves
    thread_suspend(*thread);
}
