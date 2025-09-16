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

#ifndef PROCENVIRONMENT_SURFACE_H
#define PROCENVIRONMENT_SURFACE_H

#import <Foundation/Foundation.h>
#import <LindChain/Multitask/LDEProcessManager.h>
#include <sys/sysctl.h>

// MARK: The fastest way to exchange process information HAHA

typedef struct {
    /* Real structure */
    struct kinfo_proc real;
    
    /* Now we come to my other things */
    /* Because its important */
    char path[PATH_MAX];
} kinfo_info_surface_t;

NSFileHandle *proc_surface_handoff(void);
NSFileHandle *proc_safety_handoff(void);

int proc_libproc_listallpids(void *buffer, int buffersize);
int proc_libproc_name(pid_t pid, void * buffer, uint32_t buffersize);
int proc_libproc_pidpath(pid_t pid, void * buffer, uint32_t buffersize);
int proc_libproc_pidinfo(pid_t pid, int flavor, uint64_t arg, void * buffer, int buffersize);

/// Desgined for 3rd party executables so they cannot alter the surface at runtime
void proc_3rdparty_app_endcommitment(LDEProcess *process);

void proc_surface_init(BOOL host);

#endif
