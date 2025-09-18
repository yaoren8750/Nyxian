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

#import <LindChain/ProcEnvironment/Surface/proc.h>

kinfo_info_surface_t proc_object_for_pid(pid_t pid)
{
    flock(safety_fd, LOCK_SH);
    kinfo_info_surface_t cur = {};
    for(uint32_t i = 0; i < surface->proc_count; i++)
    {
        kinfo_info_surface_t object = surface->proc_info[i];
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

    //uint32_t count = *proc_surface_object_array_count;
    for (uint32_t i = 0; i < surface->proc_count; i++) {
        if (surface->proc_info[i].real.kp_proc.p_pid == pid) {
            if (i < surface->proc_count - 1) {
                memmove(&surface->proc_info[i],
                        &surface->proc_info[i + 1],
                        (surface->proc_count - i - 1) * sizeof(kinfo_info_surface_t));
            }
            surface->proc_count--;
            break;
        }
    }

    flock(safety_fd, LOCK_UN);
}

void proc_object_insert(kinfo_info_surface_t object)
{
    flock(safety_fd, LOCK_EX);
    
    for(uint32_t i = 0; i < surface->proc_count; i++)
    {
        if(surface->proc_info[i].real.kp_proc.p_pid == object.real.kp_proc.p_pid) {
            memcpy(&surface->proc_info[i], &object, sizeof(kinfo_info_surface_t));
            flock(safety_fd, LOCK_UN);
            return;
        }
    }
    
    memcpy(&surface->proc_info[surface->proc_count++], &object, sizeof(kinfo_info_surface_t));
    
    flock(safety_fd, LOCK_UN);
}

kinfo_info_surface_t proc_object_at_index(uint32_t index)
{
    flock(safety_fd, LOCK_SH);
    kinfo_info_surface_t cur = {};
    
    if(surface->proc_count < index)
    {
        flock(safety_fd, LOCK_UN);
        return cur;
    }
    
    cur = surface->proc_info[index];
    
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
