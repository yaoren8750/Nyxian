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

#import <LindChain/ProcEnvironment/fd_map_object.h>
#import <LindChain/LiveContainer/Tweaks/libproc.h>
#import <xpc/xpc.h>

@implementation FD_MAP_OBJECT

- (void)copy_fd_map
{
    // Getting our own pid
    pid_t pid = getpid();
    int bufferSize = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, NULL, 0);
    if (bufferSize <= 0) return;

    // Allocating request buffer
    struct proc_fdinfo *fdinfo = malloc(bufferSize);
    if (!fdinfo) return;

    // Getting process identifier information
    int count = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, fdinfo, bufferSize);
    if (count <= 0)
    {
        free(fdinfo);
        return;
    }
    
    _fd_map = [[NSMutableArray alloc] init];
    
    int numFDs = count / sizeof(struct proc_fdinfo);

    for (int i = 0; i < numFDs; i++) {
        int fd = fdinfo[i].proc_fd;
        @try {
            xpc_object_t dict = xpc_dictionary_create_empty();
            xpc_dictionary_set_fd(dict, "actual_fd", fd);
            xpc_dictionary_set_int64(dict, "wished_fd", fd);
            [_fd_map addObject:dict];
        } @catch (__unused NSException *ex) {
            continue;
        }
    }

    free(fdinfo);
    return;
}

/// Intended for a brand new process, overmapping the fd map
- (void)apply_fd_map
{
    for(xpc_object_t entry in _fd_map)
    {
        int wished_fd   = (int)xpc_dictionary_get_int64(entry, "wished_fd");
        int incoming_fd = xpc_dictionary_dup_fd(entry, "actual_fd");

        if (incoming_fd >= 0)
        {
            if (dup2(incoming_fd, wished_fd) < 0)
            {
                perror("dup2");
            }
            if (incoming_fd != wished_fd)
            {
                close(incoming_fd);
            }
        }
    }
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder
{
    [coder encodeObject:_fd_map forKey:@"fd_map"];
    return;
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
{
    _fd_map = [coder decodeObjectOfClasses:[NSSet setWithObjects:
                                                  [NSArray class],
                                                  [NSObject<OS_xpc_object> class],
                                                  nil]
                                          forKey:@"fd_map"];
    return nil;
}

@end
