/*
 Copyright (C) 2025 cr4zyengineer
 Copyright (C) 2025 expo

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

#import <Foundation/Foundation.h>

int linker(int argc, char **argv);

// MEOW :3
int LinkMachO(NSMutableArray *flags) {
    // Allocating a C array by the given _flags array
    const int argc = (int)[flags count] + 1;
    char **argv = (char **)malloc(sizeof(char*) * argc);
    argv[0] = strdup("ld64.lld");
    for(int i = 1; i < argc; i++) argv[i] = strdup([[flags objectAtIndex:i - 1] UTF8String]);

    // Compile and get the resulting integer
    const int result = linker(argc, argv);
    
    // Deallocating the entire C array
    for(int i = 0; i < argc; i++) free(argv[i]);
    free(argv);
    
    return result;
}
