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
#import <mach-o/dyld.h>

surface_map_t *surface = NULL;
spinlock_t *spinface = NULL;

/* sysctl */
int proc_sysctl_listproc(void *buffer, size_t buffersize, size_t *needed_out)
{
    // Dont use if uninitilized
    if(surface == NULL) return 0;
    
    size_t needed_bytes = 0;
    int ret = 0;
    unsigned long seq;

    do {
        seq = spinlock_read_begin(spinface);

        uint32_t count = surface->proc_count;
        needed_bytes = (size_t)count * sizeof(struct kinfo_proc);

        if(needed_out)
            *needed_out = needed_bytes;

        if(buffer == NULL || buffersize == 0)
        {
            ret = (int)needed_bytes;
            break;
        }

        if(buffersize < needed_bytes)
        {
            errno = ENOMEM;
            ret = -1;
            break;
        }

        struct kinfo_proc *kprocs = buffer;
        for(uint32_t i = 0; i < count; i++)
        {
            memset(&kprocs[i], 0, sizeof(struct kinfo_proc));
            memcpy(&kprocs[i],
                   &surface->proc_info[i].real,
                   sizeof(struct kinfo_proc));
        }

        ret = (int)needed_bytes;

    } while (spinlock_read_retry(spinface, seq));

    return ret;
}

/*
 Management
 */
/// Returns a process surface file handle to perform a handoff over XPC
MappingPortObject *proc_surface_handoff(void)
{
    return [[MappingPortObject alloc] initWithAddr:surface withSize:SURFACE_MAP_SIZE withProt:VM_PROT_READ];
}

/// Returns a safety surface file handle to perform a handoff over XPC
MappingPortObject *proc_spinface_handoff(void)
{
    return [[MappingPortObject alloc] initWithAddr:spinface withSize:sizeof(spinlock_t) withProt:VM_PROT_READ];
}

/*
 Experimental hooks & implementations
 */
int environment_gethostname(char *buf,
                            size_t bufsize)
{
    unsigned long seq;

    do
    {
        seq = spinlock_read_begin(spinface);
        strlcpy(buf, surface->hostname, bufsize);
    }
    while(spinlock_read_retry(spinface, seq));
    
    return 0;
}

void kern_sethostname(NSString *hostname)
{
    spinlock_lock(spinface);
    hostname = hostname ?: @"localhost";
    strlcpy(surface->hostname, [hostname UTF8String], MAXHOSTNAMELEN);
    spinlock_unlock(spinface);
}

void proc_surface_init(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(environment_is_role(EnvironmentRoleHost))
        {
            // Allocate surface and spinface
            surface = mmap(NULL, SURFACE_MAP_SIZE, PROT_WRITE | PROT_READ, MAP_ANONYMOUS | MAP_SHARED, -1, 0);
            spinface = mmap(NULL, sizeof(spinlock_t), PROT_WRITE | PROT_READ, MAP_ANONYMOUS | MAP_SHARED, -1, 0);
            
            // Setup surface
            surface->magic = SURFACE_MAGIC;
            NSString *hostname = [[NSUserDefaults standardUserDefaults] stringForKey:@"LDEHostname"];
            if(hostname == nil) hostname = @"localhost";
            strlcpy(surface->hostname, hostname.UTF8String, MAXHOSTNAMELEN);
            surface->proc_count = 0;
            proc_create_child_proc(getppid(), getpid(), 0, 0, [[NSBundle mainBundle] executablePath], PEEntitlementAll);
            
            
            // Setup spinface
            spinface->lock = false;
            spinface->seq = 0;
        }
        else
        {
            // Get surface objects
            MappingPortObject *surfaceMapObject = nil;
            MappingPortObject *spinfaceMapObject = nil;
            
            environment_proxy_get_surface_mappings(&surfaceMapObject, &spinfaceMapObject);
            
            if(surfaceMapObject != nil &&
               spinfaceMapObject != nil)
            {
                // Now map em
                void *surfacePtr = [surfaceMapObject mapAndDestroy];
                void *spinfacePtr = [spinfaceMapObject mapAndDestroy];
                
                if(surfacePtr != MAP_FAILED &&
                   spinfacePtr != MAP_FAILED)
                {
                    surface = surfacePtr;
                    spinface = spinfacePtr;
                }
            }
        }
    });
}
