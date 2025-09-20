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

#ifndef PROCENVIRONMENT_POSIXSPAWN_H
#define PROCENVIRONMENT_POSIXSPAWN_H

#import <Foundation/Foundation.h>
#include <spawn.h>

// MARK: Simple structure to keep track
typedef struct {
    int **dup2_actions;
    size_t dup2_cnt;
    
    int *close_actions;
    size_t close_cnt;
} environment_posix_spawn_file_actions_t;

@interface PosixSpawnFileActionsObject : NSObject <NSSecureCoding>

@property (nonatomic) NSArray<NSNumber*> *closeActions;
@property (nonatomic) NSDictionary<NSNumber *, NSFileHandle*> *dup2Actions;

- (instancetype)initWithFileActions:(const environment_posix_spawn_file_actions_t **)fa;

+ (instancetype)empty;

@end

void environment_posix_spawn_init(BOOL host);

int environment_posix_spawn(pid_t *process_identifier,
                            const char *path,
                            const environment_posix_spawn_file_actions_t **fa,
                            const posix_spawnattr_t *spawn_attr,
                            char *const argv[],
                            char *const envp[]);

int environment_posix_spawnp(pid_t *process_identifier,
                             const char *path,
                             const environment_posix_spawn_file_actions_t **file_actions,
                             const posix_spawnattr_t *spawn_attr,
                             char *const argv[],
                             char *const envp[]);

#endif /* PROCENVIRONMENT_POSIXSPAWN_H */
