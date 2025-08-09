/*
 Copyright (C) 2025 cr4zyengineer
 Copyright (C) 2025 expo

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

typedef struct stack_frame {
    struct stack_frame *fp;
    uintptr_t lr;
} stack_frame_t;

const char *symbol_for_address(void *addr) {
    static char buffer[256];
    Dl_info info;
    if (dladdr(addr, &info) && info.dli_sname) {
        snprintf(buffer, sizeof(buffer), "%s", info.dli_sname);
        return buffer;
    }
    return "<unknown>";
}

NSString* stack_trace_from_thread_state(arm_thread_state64_t state,
                                        int ignoreDepth) {
    NSString *stringNS = @"Call Trace\n";
    
    stack_frame_t *frame = (stack_frame_t *)state.__fp;
    for(int depth = 0; depth < ignoreDepth; depth++)
        frame = frame->fp;
    
    if (frame && frame->lr) {
        stringNS = [stringNS stringByAppendingFormat:@"Exception Raised at %s\n%@\n\n", symbol_for_address((void *)frame->lr),
                    [Decompiler getDecompiledCodeBuffer:(UInt64)frame->lr - 4]];
    }
    
    frame = frame->fp;

    int depth = 0;

    while (frame && depth < 64) {
        void *ret = (void *)frame->lr;
        const char *name = symbol_for_address(ret);
        if(strcmp(name, "<unknown>") != 0)
            stringNS = [stringNS stringByAppendingFormat:@"%s\n%@\n\n", name, [Decompiler getDecompiledCodeBuffer:(UInt64)ret - 4]];

        frame = frame->fp;
        depth++;
    }
    
    return stringNS;
}
