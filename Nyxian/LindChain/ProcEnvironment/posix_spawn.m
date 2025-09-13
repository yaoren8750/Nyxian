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

#pragma mark - poxix_spawn helper

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
                            const posix_spawn_file_actions_t *file_actions,
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
        
        // Now since we have executable path we execute
        // TODO: Implement envp
        [hostProcessProxy spawnProcessWithPath:[NSString stringWithCString:path encoding:NSUTF8StringEncoding]
                                 withArguments:createNSArrayFromArgv(count, (char**)argv) withEnvironmentVariables:@{}
                                     withReply:^(pid_t new_process_identifier)
         {
            *process_identifier = new_process_identifier;
            dispatch_semaphore_signal(environment_semaphore);
        }];
        dispatch_semaphore_wait(environment_semaphore, DISPATCH_TIME_FOREVER);
    }
    
    return 0;
}

int environment_posix_spawnp(pid_t *process_identifier,
                             const char *path,
                             const posix_spawn_file_actions_t *file_actions,
                             const posix_spawnattr_t *spawn_attr,
                             char *const argv[],
                             char *const envp[])
{
    // Itterates through PATH variable
    // Essentially for dash which uses PATH
    return environment_posix_spawn(process_identifier, environment_which(path), file_actions, spawn_attr, argv, envp);
}

#pragma mark - posix file actions

// MARK: Simple structure to keep track
typedef struct {
    int **dup2_actions;
    size_t dup2_cnt;
    
    int *close_actions;
    size_t close_cnt;
} environment_posix_spawn_file_actions_t;


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
    for(int i = 0; i < (*fa)->close_cnt; i++)
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
    // Allocate a slice where the 1st item wil be host_fd and the 2nd child_fd
    int *slice = calloc(2, sizeof(int));
    
    // Now slide host_fd and child_fd into the slice
    slice[0] = host_fd;
    slice[1] = child_fd;                                    // MARK: Note for later, for my self, do never create a NSFileHandle from this, this is just the raw number that will be targeted in the child process
    
    // Now allocate one more slot
    (*fa)->dup2_cnt++;
    (*fa)->dup2_actions = realloc((*fa)->dup2_actions, sizeof(void*) * (*fa)->dup2_cnt);
    (*fa)->dup2_actions[(*fa)->dup2_cnt--] = slice;
    
    return 0;
}

int environment_posix_spawn_file_actions_addclose(environment_posix_spawn_file_actions_t **fa,
                                                  int child_fd)
{
    // Now allocate one more slot
    (*fa)->close_cnt++;
    (*fa)->close_actions = realloc((*fa)->dup2_actions, sizeof(int) * (*fa)->close_cnt);
    (*fa)->close_actions[(*fa)->close_cnt--] = child_fd;
    
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
