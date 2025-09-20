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
#import <LindChain/ProcEnvironment/posix_spawn.h>
#import <LindChain/litehook/src/litehook.h>
#include <mach/mach.h>
#import <pthread.h>
#include <stdarg.h>

typedef struct {
    /* Stack properties*/
    void *stack_recovery_buffer;
    void *stack_copy_buffer;
    size_t stack_recovery_size;
    
    /* Flags */
    pid_t ret_pid;
    uint8_t fork_flag;
    
    /* ThreadID */
    mach_msg_type_number_t thread_count;
    arm_thread_state64_t thread_state;
    thread_act_t thread;
} thread_snapshot_t;

__thread thread_snapshot_t *local_thread_snapshot = NULL;

void *helper_thread(void *args)
{
    // Get snapshot
    thread_snapshot_t *snapshot = args;
    
    if(snapshot->fork_flag != 0)
    {
        // MARK: This means the spawn was essentially requested
        // Safe thread state
        snapshot->thread_count = ARM_THREAD_STATE64_COUNT;
        thread_act_t thread = snapshot->thread;
        thread_suspend(snapshot->thread);
        thread_get_state(snapshot->thread, ARM_THREAD_STATE64, (thread_state_t)(&snapshot->thread_state), &snapshot->thread_count); // When ever we set the state back we need to set the PC counter to a other function, it will return normally to the caller, thats for sure.. because we dont create a new stack frame, we dont hit ret in this state for it it looks like its still in helper_thread
        
        // Allocate
        snapshot->stack_copy_buffer = malloc(snapshot->stack_recovery_size);
        
        // Copy
        memcpy(snapshot->stack_copy_buffer, snapshot->stack_recovery_buffer, snapshot->stack_recovery_size);
        
        // ret_pid to 0 to indicate running as child
        snapshot->ret_pid = 0;
        snapshot->fork_flag = 0;
        
        // Unfreeze
        thread_resume(thread);
    }
    else
    {
        // MARK: This means the spawn is happening
        // Restore thread state
        thread_suspend(snapshot->thread);
        thread_set_state(snapshot->thread, ARM_THREAD_STATE64, (thread_state_t)(&snapshot->thread_state), snapshot->thread_count);
        
        // Copy back
        memcpy(snapshot->stack_recovery_buffer, snapshot->stack_copy_buffer, snapshot->stack_recovery_size);
        free(snapshot->stack_copy_buffer);
        
        // Set flag back
        snapshot->fork_flag = 1;
        
        thread_resume(snapshot->thread);
    }
    return NULL;
}

// MARK: The first pass returns 0, call to execl() or similar will result in the callers thread being restored
pid_t environment_fork(void)
{
    // Create local snapshot
    local_thread_snapshot = malloc(sizeof(thread_snapshot_t));
    
    // Prepare for copy
    pthread_t thread = pthread_self();
    local_thread_snapshot->stack_recovery_size = pthread_get_stacksize_np(thread);
    local_thread_snapshot->stack_recovery_buffer = pthread_get_stackaddr_np(thread) - local_thread_snapshot->stack_recovery_size;
    
    // Create thread and join
    local_thread_snapshot->fork_flag = 1;
    local_thread_snapshot->thread = mach_thread_self();
    pthread_t nthread;
    pthread_create(&nthread, NULL, helper_thread, local_thread_snapshot);
    pthread_join(nthread, NULL);
    
    pid_t pid = local_thread_snapshot->ret_pid;
    if(pid != 0)
    {
        free(local_thread_snapshot);
    }
    
    return pid;
}

extern char **environ;
int environment_execl(const char * __path, const char * __arg0, ...)
{
    // Check if it was even created
    // TODO: Somehow implement execl(3) without relying on fork()
    if(!local_thread_snapshot) return EFAULT;
    
    // Now create argv
    va_list ap;
    int argc = 0;
    
    // First pass: count arguments
    va_start(ap, __arg0);
    const char *arg = __arg0;
    while(arg != NULL)
    {
        argc++;
        arg = va_arg(ap, const char *);
    }
    va_end(ap);
    
    // Allocate argv
    char **argv = malloc((argc + 1) * sizeof(char *));
    if(argv == NULL)
    {
        perror("malloc");
        return -1;
    }
    
    // Stuff argv
    va_start(ap, __arg0);
    arg = __arg0;
    for(int i = 0; i < argc; i++)
    {
        argv[i] = (char *)arg;
        arg = va_arg(ap, const char *);
    }
    argv[argc] = NULL;
    va_end(ap);
    
    // Spawn using my own posix_spawn() fix
    pid_t pid = 0;
    environment_posix_spawn(&pid, __path, nil, nil, argv, environ);
    
    // Set ret_pid
    local_thread_snapshot->ret_pid = 1;
    
    if(local_thread_snapshot->ret_pid == 0)
    {
        // Create thread and join
        pthread_t nthread;
        pthread_create(&nthread, NULL, helper_thread, local_thread_snapshot);
        pthread_join(nthread, NULL);
    }
    
    return EFAULT;
}

void environment_fork_init(BOOL host)
{
    if(!host)
    {
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, fork, environment_fork, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, execl, environment_execl, nil);
    }
}
