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

#import <LindChain/ProcEnvironment/environment.h>
#import <LindChain/ProcEnvironment/Surface/surface.h>
#import <LindChain/ProcEnvironment/Surface/proc.h>
#import <LindChain/ProcEnvironment/Surface/memfd.h>
#import <LindChain/ProcEnvironment/proxy.h>
#import <LindChain/litehook/src/litehook.h>
#import <mach/mach.h>
#import <sys/sysctl.h>

surface_map_t *surface = NULL;

static int sharing_fd = -1;
int safety_fd = -1;

/* sysctl */
int proc_sysctl_listproc(void *buffer, size_t buffersize, size_t *needed_out)
{
    flock(safety_fd, LOCK_SH);

    size_t needed_bytes = (size_t)surface->proc_count * sizeof(struct kinfo_proc);

    if(needed_out) *needed_out = needed_bytes;

    if(buffer == NULL || buffersize == 0)
    {
        flock(safety_fd, LOCK_UN);
        return (int)needed_bytes;
    }

    if(buffersize < needed_bytes)
    {
        flock(safety_fd, LOCK_UN);
        errno = ENOMEM;
        if(needed_out) *needed_out = needed_bytes;
        return -1;
    }

    struct kinfo_proc *kprocs = buffer;
    for(uint32_t i = 0; i < surface->proc_count; i++)
    {
        memset(&kprocs[i], 0, sizeof(struct kinfo_proc));
        memcpy(&kprocs[i], &surface->proc_info[i].real, sizeof(struct kinfo_proc));
    }

    flock(safety_fd, LOCK_UN);
    return (int)needed_bytes;
}

void proc_3rdparty_app_endcommitment(NSString *executablePath)
{
    // Insert self, before securing it!
    proc_insert_self();
    
    // Overwrite some info if process is passed
    kinfo_info_surface_t kinfo = proc_object_for_pid(getpid());
    
    if(executablePath)
    {
        // Modifying self
        strncpy(kinfo.real.kp_proc.p_comm, [[[NSURL fileURLWithPath:executablePath] lastPathComponent] UTF8String], MAXCOMLEN + 1);
        strncpy(kinfo.path, [executablePath UTF8String], PATH_MAX);
    }
    
    kinfo.force_task_role_override = true;
    kinfo.task_role_override = TASK_UNSPECIFIED;
    
    proc_object_insert(kinfo);
    
    // Thank you Duy Tran for the mach symbol notice in dyld_bypass_validation
    kern_return_t kr = _kernelrpc_mach_vm_protect_trap(mach_task_self(), (mach_vm_address_t)surface, SURFACE_MAP_SIZE, TRUE, VM_PROT_READ);
    if(kr != KERN_SUCCESS)
    {
        // Its not secure, our own sandbox policies got broken, we blind the process
        munmap(surface, SURFACE_MAP_SIZE);
        return;
    }
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
 Experimental hooks & implementations
 */
int environment_gethostname(char *buf,
                            size_t bufsize)
{
    flock(safety_fd, LOCK_SH);
    strncpy(buf, surface->hostname, bufsize);
    flock(safety_fd, LOCK_UN);
    
    return 0;
}

void kern_sethostname(NSString *hostname)
{
    hostname = hostname ?: @"localhost";
    strncpy(surface->hostname, [hostname UTF8String], MAXHOSTNAMELEN);
}

/*
 Init
 */
void proc_surface_init(void)
{
    // Initilize base of mapping
    if(environment_is_role(EnvironmentRoleHost))
    {
        sharing_fd = memfd_create("proc_surface_memfd", O_CREAT | O_RDWR);
        safety_fd = memfd_create("proc_surface_safefd", O_CREAT | O_RDONLY);
        ftruncate(sharing_fd, SURFACE_MAP_SIZE);
    }
    else
    {
        NSFileHandle *handle;
        NSFileHandle *safety;
        environment_proxy_get_surface_handle(&handle, &safety);
        if(!(handle && safety))
        {
            if(handle) [handle closeFile];
            if(safety) [safety closeFile];
            return;
        }
        sharing_fd = handle.fileDescriptor;
        safety_fd = safety.fileDescriptor;
    }
    
    // Now map it!! (but only with max readable)
    surface = mmap(NULL, SURFACE_MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, sharing_fd, 0);
    if(environment_is_role(EnvironmentRoleGuest) || surface == MAP_FAILED) close(sharing_fd);
    if(surface == MAP_FAILED)
    {
        // Mapping failed
        close(safety_fd);
        return;
    }
    
    // After close we come to magic
    if(environment_is_role(EnvironmentRoleHost))
    {
        // Were the host so we write the magic
        surface->magic = SURFACE_MAGIC;
    }
    else
    {
        // Were the guest so we check the magic
        if(surface->magic != SURFACE_MAGIC)
        {
            munmap(surface, SURFACE_MAP_SIZE);
            return;
        }
    }
    
    // Add proc self if were host
    if(environment_is_role(EnvironmentRoleHost))
    {
        proc_insert_self();
        
        NSString *hostname = [[NSUserDefaults standardUserDefaults] stringForKey:@"LDEHostname"];
        hostname = hostname ?: @"localhost";
        strncpy(surface->hostname, [hostname UTF8String], MAXHOSTNAMELEN);
    }
    else
    {
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, gethostname, environment_gethostname, nil);
    }
    
    return;
}
