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
#import <LindChain/ProcEnvironment/proxy.h>
#import <mach/mach.h>

#define PROC_SURFACE_MAGIC 0xFABCDEFB
#define PROC_SURFACE_OBJECT_MAX 500
#define PROC_SURFACE_OBJECT_MAX_SIZE sizeof(proc_object_t) * 500

int sharing_fd = -1;
int safety_fd = -1;
void *surface_start;

uint32_t *proc_surface_object_array_count;
static proc_object_t *proc_surface_object_array = NULL;

/*
 Read and Write of process information
 */
proc_object_t proc_object_for_pid(pid_t pid)
{
    flock(safety_fd, LOCK_SH);
    proc_object_t cur = {};
    for(uint32_t i = 0; i < *proc_surface_object_array_count; i++)
    {
        proc_object_t object = proc_surface_object_array[i];
        if(object.pid == pid) {
            cur = object;
            break;
        }
    }
    flock(safety_fd, LOCK_UN);
    return cur;
}

void proc_object_insert(proc_object_t object)
{
    flock(safety_fd, LOCK_EX);
    
    // First we look if it already exists
    for(uint32_t i = 0; i < *proc_surface_object_array_count; i++)
    {
        proc_object_t *mobject = &proc_surface_object_array[i];
        if(mobject->pid == object.pid) {
            // Now we will basically override it
            memcpy(mobject, &object, sizeof(proc_object_t));
            return;;
        }
    }
    
    // To append we just add it to the end of the array
    proc_object_t *dest = &proc_surface_object_array[(*proc_surface_object_array_count)++];
    memcpy(dest, &object, sizeof(proc_object_t));
    
    flock(safety_fd, LOCK_UN);
}

proc_object_t proc_object_at_index(uint32_t index)
{
    flock(safety_fd, LOCK_SH);
    proc_object_t cur = {};
    
    // Do we have that index?
    if(*proc_surface_object_array_count < index)
    {
        flock(sharing_fd, LOCK_UN);
        return cur;
    }
    
    // So give it to me
    cur = proc_surface_object_array[index];
    
    flock(safety_fd, LOCK_UN);
    return cur;
}

/*
 Management
 */
NSFileHandle* proc_surface_handoff(void)
{
    return [[NSFileHandle alloc] initWithFileDescriptor:sharing_fd];
}

NSFileHandle *proc_safety_handoff(void)
{
    return [[NSFileHandle alloc] initWithFileDescriptor:safety_fd];
}

/*
 Init
 */
void proc_surface_init(BOOL host)
{
    if(host)
    {
        // Initilize surface
        sharing_fd = memfd_create("proc_surface_memfd", O_CREAT | O_RDWR);
        safety_fd = memfd_create("proc_surface_safefd", O_CREAT | O_RDONLY);
        ftruncate(sharing_fd, PROC_SURFACE_OBJECT_MAX_SIZE + (sizeof(uint32_t) * 2));
        surface_start = mmap(NULL, PROC_SURFACE_OBJECT_MAX_SIZE + (sizeof(uint32_t) * 2), PROT_READ | PROT_WRITE, MAP_SHARED, sharing_fd, 0);
        
        // Prepare to write
        off_t offset = 0;

        // Write magic
        *((uint32_t*)surface_start) = PROC_SURFACE_MAGIC;
        offset += sizeof(uint32_t);
        
        // Write count
        proc_surface_object_array_count = surface_start + offset;
        offset += sizeof(uint32_t);
        *proc_surface_object_array_count = 0;
        
        // Now were done, except no, we have to write our own process to it
        proc_surface_object_array = surface_start + offset;
        
        // Adding Nyxian
        proc_object_t object;
        strcpy(object.name, "Nyxian");
        strcpy(object.executablePath, [[[NSBundle mainBundle] executablePath] UTF8String]);
        object.pid = getpid();
        object.uid = getuid();
        object.gid = getgid();
        proc_object_insert(object);
    }
    else
    {
        // Get file handle
        NSFileHandle *handle;
        NSFileHandle *safety;
        environment_proxy_get_surface_handle(&handle, &safety);
        if(!(handle && safety)) return;
        
        // Now map it!! (but only with max readable)
        sharing_fd = handle.fileDescriptor;
        safety_fd = handle.fileDescriptor;
        surface_start = mmap(NULL, PROC_SURFACE_OBJECT_MAX_SIZE + (sizeof(uint32_t) * 2), PROT_READ | PROT_WRITE, MAP_SHARED, sharing_fd, 0);
        close(sharing_fd);
        
        // Thank you Duy Tran for the mach symbol notice in dyld_bypass_validation
        kern_return_t kr = _kernelrpc_mach_vm_protect_trap(mach_task_self(), (mach_vm_address_t)surface_start, PROC_SURFACE_OBJECT_MAX_SIZE + (sizeof(uint32_t) * 2), TRUE, VM_PROT_READ);
        if(kr != KERN_SUCCESS)
        {
            // Its not secure, our own sandbox policies got broken, we blind the process
            munmap(surface_start, PROC_SURFACE_OBJECT_MAX_SIZE + (sizeof(uint32_t) * 2));
            return;
        }
        
        // Is the magic matching
        off_t offset = 0;
        uint32_t magic = *((uint32_t*)surface_start);
        if(magic == PROC_SURFACE_MAGIC)
            NSLog(@"Successfully mapped proc surface!");
        offset += sizeof(uint32_t);
        
        // Map the count
        proc_surface_object_array_count = surface_start + offset;
        offset += sizeof(uint32_t);
        
        // Map the array
        proc_surface_object_array = surface_start + offset;
        
        // Look for Nyxian!
        proc_object_t nyxian = proc_object_at_index(0);
        
        NSLog(@"Pls let it be: %s | uid: %d | gid: %d | pid: %d", nyxian.name, nyxian.uid, nyxian.gid, nyxian.pid);
    }
    
    return;
}
