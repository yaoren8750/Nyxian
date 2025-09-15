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

#import <Foundation/Foundation.h>
#import <LindChain/ProcEnvironment/Surface/surface.h>
#import <LindChain/ProcEnvironment/Surface/memfd.h>
#import <mach/mach.h>

typedef struct {
    pid_t pid;
    uid_t uid;
    gid_t gid;
    
    char name[512];
    char executablePath[512];
} proc_object_t;

#define PROC_SURFACE_MAGIC 0xFABCDEFB
#define PROC_SURFACE_OBJECT_MAX 500
#define PROC_SURFACE_OBJECT_MAX_SIZE sizeof(proc_object_t) * 500

int sharing_fd = -1;
void *surface_start;

uint32_t *proc_surface_object_array_count;
static proc_object_t *proc_surface_object_array = NULL;

/*
 Read and Write of process information
 */
proc_object_t proc_object_for_pid(pid_t pid)
{
    flock(sharing_fd, LOCK_SH);
    proc_object_t cur = {};
    for(uint32_t i = 0; i < *proc_surface_object_array_count; i++)
    {
        proc_object_t object = proc_surface_object_array[i];
        if(object.pid == pid) {
            cur = object;
            break;
        }
    }
    flock(sharing_fd, LOCK_UN);
    return cur;
}

/*
 Management
 */
NSFileHandle* proc_surface_handoff(void)
{
    return [[NSFileHandle alloc] initWithFileDescriptor:sharing_fd];
}

/*
 Init
 */
__attribute__((constructor))
void proc_surface_init_host(void)
{
    // Initilize surface
    const char *name = "proc_surface_memfd";
    sharing_fd = memfd_create(name, O_CREAT | O_RDWR);
    ftruncate(sharing_fd, PROC_SURFACE_OBJECT_MAX_SIZE);
    surface_start = mmap(NULL, PROC_SURFACE_OBJECT_MAX_SIZE + (sizeof(uint32_t) * 2), PROT_READ | PROT_WRITE, MAP_SHARED, sharing_fd, 0);
    
    // Prepare to write
    off_t offset = 0;
    uint32_t magic = PROC_SURFACE_MAGIC;
    
    // Write magic
    memcpy(surface_start + offset, &magic, sizeof(uint32_t));
    offset += sizeof(uint32_t);
    
    // Write count
    proc_surface_object_array_count = surface_start + offset;
    offset += sizeof(uint32_t);
    *proc_surface_object_array_count = 1;
    
    // Now were done, except no, we have to write our own process to it
    proc_surface_object_array = surface_start + offset;
    proc_object_t *object = proc_surface_object_array;
    strcpy(object->name, "Nyxian");
    strcpy(object->executablePath, [[[NSBundle mainBundle] executablePath] UTF8String]);
    object->pid = getpid();
    object->uid = getuid();
    object->gid = getgid();
    
    /* Experimentation */
    proc_object_t lookup_proc = proc_object_for_pid(getpid());
    lookup_proc = proc_object_for_pid(getpid());
    
    return;
}
