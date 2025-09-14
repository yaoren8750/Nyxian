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
#import <LindChain/ProcEnvironment/posix_spawn.h>
#import <LindChain/Multitask/LDEProcessManager.h>
#import <LindChain/litehook/src/litehook.h>
#import <LindChain/LiveContainer/LCUtils.h>
#import <LindChain/LiveContainer/LCAppInfo.h>
#import <LindChain/LiveContainer/ZSign/zsigner.h>
#import <spawn.h>
#import <sys/sysctl.h>
#import <LindChain/LiveContainer/Tweaks/libproc.h>

#pragma mark - Horrible code nobody ever wants to read

NSArray<NSFileHandle *> *AllOpenFileHandles(void) {
    pid_t pid = getpid();
    int bufferSize = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, NULL, 0);
    if (bufferSize <= 0) return @[];

    struct proc_fdinfo *fdinfo = malloc(bufferSize);
    if (!fdinfo) return @[];

    int count = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, fdinfo, bufferSize);
    if (count <= 0) {
        free(fdinfo);
        return @[];
    }

    NSMutableArray<NSFileHandle *> *handles = [NSMutableArray array];
    int numFDs = count / sizeof(struct proc_fdinfo);

    for (int i = 0; i < numFDs; i++) {
        int fd = fdinfo[i].proc_fd;
        @try {
            NSFileHandle *fh = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:NO];
            if (fh) [handles addObject:fh];
        } @catch (__unused NSException *ex) {
            continue;
        }
    }

    free(fdinfo);
    return [handles copy];
}

#pragma mark - Sendable objects

@implementation PosixSpawnFileActionsObject

- (instancetype)initWithFileActions:(const environment_posix_spawn_file_actions_t **)fa {
    self = [super init];
    if (self) {
        // First we need to get all file descriptors in our processs
        
        NSMutableArray *futureCloseActions = [NSMutableArray array];
        for (int i = 0; i < (*fa)->close_cnt; i++) {
            [futureCloseActions addObject:@((*fa)->close_actions[i])];
        }
        _closeActions = [futureCloseActions copy];

        NSMutableDictionary<NSNumber *, NSFileHandle *> *futureDup2 = [NSMutableDictionary dictionary];
        for (int i = 0; i < (*fa)->dup2_cnt; i++) {
            int *slice = (*fa)->dup2_actions[i];
            int host_fd = slice[0];
            int child_fd = slice[1];

            NSFileHandle *handle = [[NSFileHandle alloc] initWithFileDescriptor:host_fd
                                                                closeOnDealloc:NO];
            futureDup2[@(child_fd)] = handle;
        }
        _dup2Actions = [futureDup2 copy];
    }
    return self;
}

+ (instancetype)empty
{
    PosixSpawnFileActionsObject *instance = [[PosixSpawnFileActionsObject alloc] init];
    instance.closeActions = @[];
    instance.dup2Actions = @{};
    return instance;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder { 
    [coder encodeObject:_closeActions forKey:@"closeActions"];
    [coder encodeObject:_dup2Actions forKey:@"dup2Actions"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    self = [super init];
    _closeActions = [coder decodeObjectOfClasses:[NSSet setWithObjects:
                                                  [NSArray class],
                                                  [NSNumber class],
                                                  nil]
                                          forKey:@"closeActions"];
    _dup2Actions = [coder decodeObjectOfClasses:[NSSet setWithObjects:
                                                 [NSDictionary class],
                                                 [NSNumber class],
                                                 [NSFileHandle class],
                                                 nil] forKey:@"dup2Actions"];
    return self;
}

@end

#pragma mark - posix_spawn helper

NSArray<NSString *> *createNSArrayFromArgv(int argc, char *argv[])
{
    if(argc <= 0 || argv == NULL)
    {
        return @[];
    }

    NSMutableArray<NSString *> *array = [NSMutableArray arrayWithCapacity:argc];
    for (int i = 0; i < argc; i++)
    {
        if(argv[i])
        {
            NSString *arg = [NSString stringWithUTF8String:argv[i]];
            if(arg)
            {
                [array addObject:arg];
            }
        }
    }
    return [array copy];
}

char *environment_which(const char *name)
{
    if(!name) return NULL;
    if(strchr(name, '/'))
    {
        if (access(name, X_OK) == 0)
            return realpath(name, NULL);
        return NULL;
    }
    
    char *path = getenv("PATH");
    if (!path) return NULL;
    
    char *copy = strdup(path);
    char *token = strtok(copy, ":");
    while(token)
    {
        char candidate[PATH_MAX];
        snprintf(candidate, sizeof(candidate), "%s/%s", token, name);
        if (access(candidate, X_OK) == 0) {
            free(copy);
            return realpath(candidate, NULL);
        }
        token = strtok(NULL, ":");
    }
    free(copy);
    return NULL;
}

#pragma mark - posix_spawn implementation

int environment_posix_spawn(pid_t *process_identifier,
                            const char *path,
                            const environment_posix_spawn_file_actions_t **fa,
                            const posix_spawnattr_t *spawn_attr,
                            char *const argv[],
                            char *const envp[])
{
    // Fixing executing binaries at relative paths
    char resolved[PATH_MAX];
    realpath(path, resolved);
    path = resolved;
    
    if(!environmentIsHost)
    {
        // MARK: GUEST Implementation
        
        // Check code signature
        if(!path) return 1;
        if(!checkCodeSignature(path))
        {
            // Is not valid
            NSString *signMachOAtPath(NSString *path);
            path = [signMachOAtPath([NSString stringWithCString:path encoding:NSUTF8StringEncoding]) UTF8String];
            if(!path) return 1;
        }
        
        // Is argv safe?
        if(argv == NULL) return 1;
        
        // Count argc
        int count = 0;
        while(argv[count] != NULL)
        {
            count++;
        }
        
        // Create file actions object
        PosixSpawnFileActionsObject *fileActions = [[PosixSpawnFileActionsObject alloc] initWithFileActions:fa];
        
        // Now since we have executable path we execute
        // TODO: Implement envp
        *process_identifier = environment_proxy_spawn_process_at_path([NSString stringWithCString:path encoding:NSUTF8StringEncoding],
                                                                      createNSArrayFromArgv(count, (char**)argv),
                                                                      @{},
                                                                      fileActions);
    }
    
    return 0;
}

int environment_posix_spawnp(pid_t *process_identifier,
                             const char *path,
                             const environment_posix_spawn_file_actions_t **file_actions,
                             const posix_spawnattr_t *spawn_attr,
                             char *const argv[],
                             char *const envp[])
{
    // Itterates through PATH variable
    // Essentially for dash which uses PATH
    return environment_posix_spawn(process_identifier, environment_which(path), file_actions, spawn_attr, argv, envp);
}

#pragma mark - posix file actions

// MARK: Creation and destruction
int environment_posix_spawn_file_actions_init(environment_posix_spawn_file_actions_t **fa)
{
    // Allocate structure and return
    *fa = malloc(sizeof(environment_posix_spawn_file_actions_t));
    (*fa)->dup2_cnt = 0;
    (*fa)->dup2_actions = NULL;
    (*fa)->close_cnt = 0;
    (*fa)->close_actions = NULL;
    return 0;
}

int environment_posix_spawn_file_actions_destroy(environment_posix_spawn_file_actions_t **fa)
{
    // Destroy each slices
    for(int i = 0; i < (*fa)->dup2_cnt; i++)
        free(((*fa)->dup2_actions)[i]);
    
    // Destroy structure and return
    free((*fa)->dup2_actions);
    free((*fa)->close_actions);
    return 0;
}

// MARK: Management
int environment_posix_spawn_file_actions_adddup2(environment_posix_spawn_file_actions_t **fa,
                                                 int host_fd,
                                                 int child_fd)
{
    if(!(child_fd != STDIN_FILENO | child_fd != STDOUT_FILENO | child_fd != STDERR_FILENO)) return EFAULT;
    int *slice = calloc(2, sizeof(int));
    slice[0] = host_fd;
    slice[1] = child_fd;
    
    (*fa)->dup2_cnt++;
    (*fa)->dup2_actions = realloc((*fa)->dup2_actions,
                                  sizeof(int*) * (*fa)->dup2_cnt);
    (*fa)->dup2_actions[(*fa)->dup2_cnt - 1] = slice;

    return 0;
}

int environment_posix_spawn_file_actions_addclose(environment_posix_spawn_file_actions_t **fa,
                                                  int child_fd)
{
    if(!(child_fd != STDIN_FILENO | child_fd != STDOUT_FILENO | child_fd != STDERR_FILENO)) return EFAULT;
    (*fa)->close_cnt++;
    (*fa)->close_actions = realloc((*fa)->close_actions,
                                   sizeof(int) * (*fa)->close_cnt);
    (*fa)->close_actions[(*fa)->close_cnt - 1] = child_fd;
    return 0;
}

#pragma mark - Initilizer

void environment_posix_spawn_init(BOOL host)
{
    if(!host)
    {
        // MARK: GUEST Init
        
        // MARK: Fixing spawning of child processes
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, posix_spawn, environment_posix_spawn, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, posix_spawnp, environment_posix_spawnp, nil);
        
        // MARK: Fixing file actions, so developers can redirect file descriptors
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, posix_spawn_file_actions_init, environment_posix_spawn_file_actions_init, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, posix_spawn_file_actions_destroy, environment_posix_spawn_file_actions_destroy, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, posix_spawn_file_actions_adddup2, environment_posix_spawn_file_actions_adddup2, nil);
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, posix_spawn_file_actions_addclose, environment_posix_spawn_file_actions_addclose, nil);
    }
}
