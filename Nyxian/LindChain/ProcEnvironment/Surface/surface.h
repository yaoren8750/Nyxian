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

// MARK: The fastest way to exchange process information HAHA

typedef struct {
    pid_t pid;
    uid_t uid;
    gid_t gid;
    
    char name[512];
    char executablePath[512];
} proc_object_t;

NSFileHandle* proc_surface_handoff(void);
NSFileHandle *proc_safety_handoff(void);

void proc_surface_init(BOOL host);

#endif
