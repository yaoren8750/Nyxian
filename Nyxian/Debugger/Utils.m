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

const char *symbol_for_address(void *addr)
{
    static char buffer[256];
    Dl_info info;
    if (dladdr(addr, &info) && info.dli_sname)
    {
        snprintf(buffer, sizeof(buffer), "%s", info.dli_sname);
        return buffer;
    }
    return "<unknown>";
}

typedef struct stack_frame {
    struct stack_frame *fp;
    void *lr;
} stack_frame_t;

NSString* stack_trace_from_thread_state(arm_thread_state64_t state)
{
    NSString *stringNS = @"Call Trace\n";
    
    stack_frame_t start_frame;
    start_frame.lr = (void*)state.__pc;
    start_frame.fp = (void*)state.__fp;
    stack_frame_t *frame = &start_frame;

    int depth = 0;
    while(frame && depth < 64)
    {
        const char *name = symbol_for_address(frame->lr);
        if(strcmp(name, "<unknown>") != 0)
            stringNS = [stringNS stringByAppendingFormat:@"%s\n%@\n\n", name, [Decompiler getDecompiledCodeBuffer:((UInt64)(depth == 0 ? frame->lr : frame->lr - 4))]];

        if(strcmp(name, "main") == 0)
            break;
            
        frame = frame->fp;
        depth++;
    }
    
    return stringNS;
}
