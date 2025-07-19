/*
 Copyright (C) 2025 SeanIsTethered

 This file is part of Nyxian.

 FridaCodeManager is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 FridaCodeManager is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with FridaCodeManager. If not, see <https://www.gnu.org/licenses/>.
*/

#import "EnvRecover.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern char **environ;

/*
 @Brief extension of EnvRecover holding the sensitive backup safely
 */
@interface EnvRecover ()

@property (nonatomic,readonly) char **backup;

@end

/*
 @Brief NSObject to handle changes to environment variables
 basically resetting them after use
 */
@implementation EnvRecover

- (instancetype)init
{
    self = [super init];
    return self;
}

- (void)createBackup
{
    size_t total_size = 0;
    char **env = environ;
    while (*env != NULL) {
        total_size += strlen(*env) + 1;
        env++;
    }
    total_size += sizeof(char **) * (env - environ);
    _backup = malloc(total_size);
    memcpy(_backup, environ, total_size);
}

- (void)restoreBackup
{
    size_t total_size = 0;
    char **env = _backup;
    
    while (*env != NULL) {
        total_size += strlen(*env) + 1;
        env++;
    }
    
    total_size += sizeof(char **) * (env - _backup);
    memcpy(environ, _backup, total_size);
    free(_backup);
}


@end
