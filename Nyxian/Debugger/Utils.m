//
//  Utils.m
//  Nyxian
//
//  Created by SeanIsTethered on 08.08.25.
//

#include "Utils.h"

///
/// Private API
///

typedef struct {
    task_t task;
    thread_t ownThread;
    thread_act_array_t thread_list;
    mach_msg_type_number_t thread_count;
    kern_return_t kr;
} debugger_task_t;

debugger_task_t* get_self_task(void)
{
    debugger_task_t *debuggerTask = malloc(sizeof(debugger_task_t));
    debuggerTask->task = mach_task_self();
    debuggerTask->ownThread = mach_thread_self();
    
    debuggerTask->kr = task_threads(debuggerTask->task, &debuggerTask->thread_list, &debuggerTask->thread_count);
    if(debuggerTask->kr != KERN_SUCCESS)
    {
        mach_port_deallocate(debuggerTask->task, debuggerTask->ownThread);
        free(debuggerTask);
        return NULL;
    }
    
    return debuggerTask;
}

void release_self_task(debugger_task_t *debuggerTask)
{
    mach_port_deallocate(debuggerTask->task, debuggerTask->ownThread);
    for (mach_msg_type_number_t i = 0; i < debuggerTask->thread_count; i++) {
            mach_port_deallocate(debuggerTask->task, debuggerTask->thread_list[i]);
        }
        vm_deallocate(debuggerTask->task, (vm_address_t)debuggerTask->thread_list,
                      debuggerTask->thread_count * sizeof(thread_t));
    free(debuggerTask);
}

///
/// Public API
///

/*
 Symbol to suspend all threads except our own one
 */
kern_return_t suspend_self_task(void)
{
    debugger_task_t *debuggerTask = get_self_task();
    for(mach_msg_type_number_t i = 0; i < debuggerTask->thread_count; i++)
    {
        thread_t childThreadPort = debuggerTask->thread_list[i];
        if(childThreadPort != debuggerTask->ownThread)
        {
            debuggerTask->kr = thread_suspend(childThreadPort);
            if(debuggerTask->kr != KERN_SUCCESS)
                return debuggerTask->kr;
        }
    }
    release_self_task(debuggerTask);
    
    return KERN_SUCCESS;
}

/*
 Symbol to resume all threads except our own one
 */
kern_return_t resume_self_task(void)
{
    debugger_task_t *debuggerTask = get_self_task();
    for(mach_msg_type_number_t i = 0; i < debuggerTask->thread_count; i++)
    {
        thread_t childThreadPort = debuggerTask->thread_list[i];
        if(childThreadPort != debuggerTask->ownThread)
        {
            debuggerTask->kr = thread_resume(childThreadPort);
            if(debuggerTask->kr != KERN_SUCCESS)
                return debuggerTask->kr;
        }
    }
    release_self_task(debuggerTask);
    
    return KERN_SUCCESS;
}
