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

#pragma mark - posix_spawn implementation

int environment_posix_spawn(pid_t *process_identifier,
                            const char *path,
                            const posix_spawn_file_actions_t *file_actions,
                            const posix_spawnattr_t *spawn_attr,
                            char *const argv[],
                            char *const envp[])
{
    if(!environmentIsHost)
    {
        // MARK: GUEST Implementation
        
        // Check code signature
        if(!path) return 1;
        if(!checkCodeSignature(path))
        {
            NSLog(@"Big nono!");
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

#pragma mark - Initilizer

void environment_posix_spawn_init(BOOL host)
{
    if(!host)
    {
        // MARK: GUEST Init
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, posix_spawn, environment_posix_spawn, nil);
    }
}
