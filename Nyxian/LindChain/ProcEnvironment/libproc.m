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
#import <LindChain/ProcEnvironment/environment.h>
#import <LindChain/ProcEnvironment/proxy.h>
#import <LindChain/ProcEnvironment/libproc.h>
#import <LindChain/litehook/src/litehook.h>
#import <LindChain/LiveContainer/Tweaks/libproc.h>
#import <LindChain/ProcEnvironment/Surface/surface.h>
#import <LindChain/ProcEnvironment/Surface/proc.h>

int proc_libproc_listallpids(void *buffer, int buffersize)
{
    if(buffersize < 0)
    {
        errno = EINVAL;
        return -1;
    }
    
    size_t n = 0;
    size_t needed_bytes = 0;

    do
    {
        seqlock_read_begin(&(surface->seqlock));

        uint32_t count = surface->proc_count;
        needed_bytes = (size_t)count * sizeof(pid_t);

        if (buffer != NULL && buffersize > 0) {
            size_t capacity = (size_t)buffersize / sizeof(pid_t);
            n = count < capacity ? count : capacity;

            pid_t *pids = (pid_t *)buffer;
            for (size_t i = 0; i < n; i++) {
                pids[i] = surface->proc_info[i].real.kp_proc.p_pid;
            }
        }

    }
    while (seqlock_read_retry(&(surface->seqlock)));
    
    if(buffer == NULL || buffersize == 0)
    {
        return (int)needed_bytes;
    }
    
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

void environment_libproc_init(void)
{
    if(environment_is_role(EnvironmentRoleGuest))
    {
        // MARK: GUEST Init
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, proc_listallpids, proc_libproc_listallpids, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, proc_name, proc_libproc_name, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, proc_pidpath, proc_libproc_pidpath, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, proc_pidinfo, proc_libproc_pidinfo, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, proc_pid_rusage, proc_libproc_pid_rusage, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, kill, environment_proxy_proc_kill_process_identifier, nil);
    }
}
