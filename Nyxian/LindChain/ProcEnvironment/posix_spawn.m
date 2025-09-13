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
#import <LindChain/ProcEnvironment/posix_spawn.h>
#import <LindChain/Multitask/LDEProcessManager.h>
#import <LindChain/litehook/src/litehook.h>
#import <spawn.h>

#pragma mark - posix_spawn implementation

int environment_posix_spawn(pid_t *process_identifier,
                            const posix_spawn_file_actions_t *file_actions,
                            const posix_spawnattr_t *spawn_attr,
                            char *const argv[__restrict],
                            char *const envp[__restrict])
{
    if(environmentIsHost)
    {
        // MARK: First host implementation, first the basics
        // Extract executables path from arguments
        const char *executablePath = argv[0];
        
        // Check if executable path is not null
        if(!executablePath) return 1;
        
        // Now since we have executable path we execute
        return [[LDEProcessManager shared] spawnProcessWithExecutablePath:[NSString stringWithCString:executablePath encoding:NSUTF8StringEncoding]];
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
