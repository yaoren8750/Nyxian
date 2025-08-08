//
//  Utils.h
//  Nyxian
//
//  Created by SeanIsTethered on 08.08.25.
//

#include <stdlib.h>
#include <mach/mach.h>
#include <mach/exc.h>
#include <mach/exception.h>
#include <mach/exception_types.h>
#include <mach/thread_act.h>
#include <mach/thread_state.h>

kern_return_t suspend_self_task(void);
kern_return_t resume_self_task(void);
