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
#import <LindChain/ProcEnvironment/proxy.h>
#import <LindChain/ProcEnvironment/sysctl.h>
#import <LindChain/litehook/src/litehook.h>
#include <sys/sysctl.h>

struct kinfo_proc environment_own_kinfo_proc(void)
{
    static struct kinfo_proc proc = {};
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size_t len = sizeof(proc);
        
        // mib = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        int mib[4];
        mib[0] = CTL_KERN;
        mib[1] = KERN_PROC;
        mib[2] = KERN_PROC_PID;
        mib[3] = getpid();
        
        if (sysctl(mib, 4, (void*)(&proc), &len, NULL, 0) == -1) {
            perror("sysctl");
        }
    });
    return proc;
}

struct kinfo_proc environment_kinfo_proc_for_process_identifier(pid_t pid)
{
    struct kinfo_proc proc = environment_own_kinfo_proc();
    
    // Gather process structure
    LDEProcess *process_structure = environment_proxy_proc_structure_for_process_identifier(pid);
    
    if(!process_structure) return proc; /* If there is no process structure we return the empty structure */
    
    /* Saved info */
    uid_t uid = process_structure.uid;
    gid_t gid = process_structure.gid;
    
    /* kp_eproc init */
    proc.kp_eproc.e_pcred.p_ruid = uid;       /* Write UID */
    proc.kp_eproc.e_pcred.p_svuid = uid;      /* Write UID */
    proc.kp_eproc.e_pcred.p_rgid = gid;       /* Write GID */
    proc.kp_eproc.e_pcred.p_svgid = gid;      /* Write GID */
    
    proc.kp_eproc.e_ucred.cr_uid = uid;       /* Write UID */
    proc.kp_eproc.e_ucred.cr_ngroups = 0;     /* Set groups to 0 */
    
    proc.kp_eproc.e_ppid = 0;                 /* Insert parent process as parent process is Nyxian insert 0 */
    proc.kp_eproc.e_pgid = getpgid(pid);      /* Insert process group identifier */
    
    /* kp_proc init*/
    proc.kp_proc.p_pid = pid;                 /* First insert givven pid into the structure */
    
    return proc;
}

DEFINE_HOOK(sysctl, int, (int *name,
                          u_int namelen,
                          void *__sized_by(*oldlenp) oldp,
                          size_t *oldlenp,
                          void *__sized_by(newlen) newp,
                          size_t newlen))
{
    // Logging
    /*NSLog(@"[sysctl] CALL!\n"
          "name: %p\n"
          "namelen: %u\n"
          "oldp: %p\n"
          "oldlenp: %p (%zu)\n"
          "newp: %p\n"
          "newlen: %zu\n",
          name,
          namelen,
          oldp,
          oldlenp, oldlenp ? *oldlenp : 0,
          newp,
          newlen);*/
    
    if(namelen == 2 && name[0] == CTL_KERN && name[1] == KERN_MAXPROC)
    {
        NSLog(@"ProcArray.m asked for maxproc to be filled");
        int *maxproc = name;
        *maxproc = 1;
        NSLog(@"Returned with 1 max prox;");
        return 0;
        
    }
    
    if(namelen == 4 && name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_ALL && name[3] == 0)
    {
        NSLog(@"ProcArray.m asked for buffer");
        if(oldlenp == NULL) return 1;
        if(oldp == NULL || *oldlenp < sizeof(struct kinfo_proc))
        {
            // Write length of kinfo_proc into *oldlenp
            *oldlenp = sizeof(struct kinfo_proc);
            return 0;
        }
        
        // Length is enough, we write it into the buffer
        struct kinfo_proc proc = environment_own_kinfo_proc();
        memcpy(oldp, &proc, sizeof(struct kinfo_proc));
        
        return 0;
    }
    
    // Call original sysctl
    return ORIG_FUNC(sysctl)(name, namelen, oldp, oldlenp, newp, newlen);
}

void environment_sysctl_init(BOOL host)
{
    if(!host)
    {
        DO_HOOK_GLOBAL(sysctl)
    }
}
