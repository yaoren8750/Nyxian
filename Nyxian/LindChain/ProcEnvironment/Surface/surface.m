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
#import <sys/sysctl.h>

// Minimal stubs if <libproc.h> is not available
#ifndef PROC_PIDTASKINFO
#define PROC_PIDTASKINFO     4
#endif
#ifndef PROC_PIDTASKALLINFO
#define PROC_PIDTASKALLINFO  2
#endif

struct proc_taskinfo {
    uint64_t        pti_virtual_size;
    uint64_t        pti_resident_size;
    uint64_t        pti_total_user;
    uint64_t        pti_total_system;
    uint64_t        pti_threads_user;
    uint64_t        pti_threads_system;
    int32_t         pti_policy;
    int32_t         pti_faults;
    int32_t         pti_pageins;
    int32_t         pti_cow_faults;
    int32_t         pti_messages_sent;
    int32_t         pti_messages_received;
    int32_t         pti_syscalls_mach;
    int32_t         pti_syscalls_unix;
    int32_t         pti_csw;
    int32_t         pti_threadnum;
    int32_t         pti_numrunning;
    int32_t         pti_priority;
};

struct proc_bsdinfo {
    // truncated stub; real struct has many fields
    uint32_t        pbi_pid;
    char            pbi_comm[20];
};

struct proc_taskallinfo {
    struct proc_bsdinfo   pbsd;
    struct proc_taskinfo  ptinfo;
};

#define PROC_SURFACE_MAGIC 0xFABCDEFB
#define PROC_SURFACE_OBJECT_MAX 500
#define PROC_SURFACE_OBJECT_MAX_SIZE sizeof(kinfo_info_surface_t) * 500

static int sharing_fd = -1;
static int safety_fd = -1;
static void *surface_start;

static uint32_t *proc_surface_object_array_count;
static kinfo_info_surface_t *proc_surface_object_array = NULL;

/*
 Read and Write of process information
 */
kinfo_info_surface_t proc_object_for_pid(pid_t pid)
{
    flock(safety_fd, LOCK_SH);
    kinfo_info_surface_t cur = {};
    for(uint32_t i = 0; i < *proc_surface_object_array_count; i++)
    {
        kinfo_info_surface_t object = proc_surface_object_array[i];
        if(object.real.kp_proc.p_pid == pid) {
            cur = object;
            break;
        }
    }
    flock(safety_fd, LOCK_UN);
    return cur;
}

void proc_object_remove_for_pid(pid_t pid)
{
    flock(safety_fd, LOCK_EX);

    uint32_t count = *proc_surface_object_array_count;
    for (uint32_t i = 0; i < count; i++) {
        if (proc_surface_object_array[i].real.kp_proc.p_pid == pid) {
            if (i < count - 1) {
                memmove(&proc_surface_object_array[i],
                        &proc_surface_object_array[i + 1],
                        (count - i - 1) * sizeof(kinfo_info_surface_t));
            }
            (*proc_surface_object_array_count)--;
            break;
        }
    }

    flock(safety_fd, LOCK_UN);
}

void proc_object_insert(kinfo_info_surface_t object)
{
    flock(safety_fd, LOCK_EX);
    
    for(uint32_t i = 0; i < *proc_surface_object_array_count; i++)
    {
        kinfo_info_surface_t *mobject = &proc_surface_object_array[i];
        if(mobject->real.kp_proc.p_pid == object.real.kp_proc.p_pid) {
            memcpy(mobject, &object, sizeof(kinfo_info_surface_t));
            flock(safety_fd, LOCK_UN);
            return;
        }
    }
    
    kinfo_info_surface_t *dest = &proc_surface_object_array[(*proc_surface_object_array_count)++];
    memcpy(dest, &object, sizeof(kinfo_info_surface_t));
    
    flock(safety_fd, LOCK_UN);
}

kinfo_info_surface_t proc_object_at_index(uint32_t index)
{
    flock(safety_fd, LOCK_SH);
    kinfo_info_surface_t cur = {};
    
    if(*proc_surface_object_array_count < index)
    {
        flock(sharing_fd, LOCK_UN);
        return cur;
    }
    
    cur = proc_surface_object_array[index];
    
    flock(safety_fd, LOCK_UN);
    return cur;
}

void proc_insert_self(void)
{
    pid_t pid = getpid();
    struct kinfo_proc kp;
    size_t len = sizeof(kp);
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, pid };
    
    if (sysctl(mib, 4, &kp, &len, NULL, 0) == -1) {
        perror("sysctl");
        return;
    }
    
    char pathbuf[PATH_MAX];
    int proc_pidpath(pid_t pid, void *buf, size_t bufsize);
    proc_pidpath(pid, pathbuf, sizeof(pathbuf));
    
    kinfo_info_surface_t info;
    info.real = kp;
    strncpy(info.path, pathbuf, sizeof(pathbuf));
    
    proc_object_insert(info);
}

/* libproc */
int proc_libproc_listallpids(void *buffer, int buffersize)
{
    if (buffersize < 0) { errno = EINVAL; return -1; }

    flock(safety_fd, LOCK_SH);

    uint32_t count = *proc_surface_object_array_count;
    size_t needed_bytes = (size_t)count * sizeof(pid_t);

    if (buffer == NULL || buffersize == 0) {
        flock(safety_fd, LOCK_UN);
        return (int)needed_bytes;
    }

    size_t capacity = (size_t)buffersize / sizeof(pid_t);
    size_t n = count < capacity ? count : capacity;

    pid_t *pids = (pid_t *)buffer;
    for (size_t i = 0; i < n; i++) {
        pids[i] = proc_surface_object_array[i].real.kp_proc.p_pid;
    }

    flock(safety_fd, LOCK_UN);

    return (int)(n * sizeof(pid_t));
}

int proc_libproc_name(pid_t pid, void * buffer, uint32_t buffersize)
{
    if (buffersize == 0 || buffer == NULL)
        return 0;

    kinfo_info_surface_t info = proc_object_for_pid(pid);
    if (info.real.kp_proc.p_pid == 0)
        return 0;

    strlcpy((char*)buffer, info.real.kp_proc.p_comm, buffersize);

    return (int)strlen((char*)buffer);
}

int proc_libproc_pidpath(pid_t pid, void * buffer, uint32_t buffersize)
{
    if (buffersize == 0 || buffer == NULL)
        return 0;

    kinfo_info_surface_t info = proc_object_for_pid(pid);
    if (info.real.kp_proc.p_pid == 0)
        return 0;

    strlcpy((char*)buffer, info.path, buffersize);
    return (int)strlen((char*)buffer);
}

int proc_libproc_pidinfo(pid_t pid, int flavor, uint64_t arg,
                 void * buffer, int buffersize)
{
    if (buffer == NULL || buffersize <= 0)
        return 0;

    kinfo_info_surface_t kinfo = proc_object_for_pid(pid);
    if (kinfo.real.kp_proc.p_pid == 0)
        return 0;

    switch (flavor) {
    case PROC_PIDTASKINFO:
        memset(buffer, 0, buffersize);
        return sizeof(struct proc_taskinfo);

    case PROC_PIDTASKALLINFO: {
        if (buffersize < sizeof(struct proc_taskallinfo))
            return 0;
        struct proc_taskallinfo *info = (struct proc_taskallinfo*)buffer;
        memset(info, 0, sizeof(*info));
        memcpy(&info->pbsd, &kinfo.real, sizeof(kinfo.real) < sizeof(info->pbsd) ? sizeof(kinfo.real) : sizeof(info->pbsd));
        return sizeof(struct proc_taskallinfo);
    }

    default:
        errno = ENOTSUP;
        return 0;
    }
}

/* sysctl */
int proc_sysctl_listproc(void *buffer, size_t buffersize, size_t *needed_out)
{
    flock(safety_fd, LOCK_SH);

    uint32_t count = *proc_surface_object_array_count;
    size_t needed_bytes = (size_t)count * sizeof(struct kinfo_proc);

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
    for(uint32_t i = 0; i < count; i++)
    {
        memset(&kprocs[i], 0, sizeof(struct kinfo_proc));
        memcpy(&kprocs[i], &proc_surface_object_array[i].real, sizeof(struct kinfo_proc));
    }

    flock(safety_fd, LOCK_UN);
    return (int)needed_bytes;
}


void proc_3rdparty_app_endcommitment(NSString *executablePath)
{
    // Insert self, before securing it!
    proc_insert_self();
    
    // Overwrite some info if process is passed
    if(executablePath)
    {
        // Getting self
        kinfo_info_surface_t kinfo = proc_object_for_pid(getpid());
        
        // Modifying self
        strncpy(kinfo.real.kp_proc.p_comm, [[[NSURL fileURLWithPath:executablePath] lastPathComponent] UTF8String], MAXCOMLEN + 1);
        strncpy(kinfo.path, [executablePath UTF8String], PATH_MAX);
        
        proc_object_insert(kinfo);
    }
    
    // Thank you Duy Tran for the mach symbol notice in dyld_bypass_validation
    kern_return_t kr = _kernelrpc_mach_vm_protect_trap(mach_task_self(), (mach_vm_address_t)surface_start, PROC_SURFACE_OBJECT_MAX_SIZE + (sizeof(uint32_t) * 2), TRUE, VM_PROT_READ);
    if(kr != KERN_SUCCESS)
    {
        // Its not secure, our own sandbox policies got broken, we blind the process
        munmap(surface_start, PROC_SURFACE_OBJECT_MAX_SIZE + (sizeof(uint32_t) * 2));
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
        proc_insert_self();
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
    }
    
    return;
}
