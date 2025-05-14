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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cstdlib>
#include <cstdio>
#include <string>
#include <pthread.h>
#include "llvm/Support/raw_ostream.h"
#import <Compiler/Compiler.h>

// TODO: Might want to extract a header
int CompileObject(int argc, const char **argv);

@interface Compiler ()

@property (nonatomic, strong) NSArray * _Nonnull flags;

@end

@implementation Compiler

///
/// Method that initilizes the more-use Compiler
///
- (instancetype)init:(NSArray*)flags
{
    self = [super init];
    
    NSString *sdkPath = [NSString stringWithFormat:@"%@/Documents/.bootstrap/iPhoneOS16.5.sdk", NSHomeDirectory()];
    NSString *includePath = [NSString stringWithFormat:@"-I%@/Documents/.bootstrap/include", NSHomeDirectory()];
    
    _flags = [flags copy];
    [_flags arrayByAddingObject:@"-isysroot"];
    [_flags arrayByAddingObject:sdkPath];
    [_flags arrayByAddingObject:includePath];
    
    return self;
}

///
/// Method that compiles a object file for a given file path
///
- (int)compileObject:(nonnull NSString*)filePath
{
    NSMutableArray<NSString *> *args = [NSMutableArray arrayWithArray:@[
        @"clang",
        [filePath copy]
    ]];

    [args addObjectsFromArray:_flags];

    int argc = (int)[args count];
    const char **argv = (const char **)malloc(sizeof(char*) * argc);
    for (int i = 0; i < argc; i++) {
        argv[i] = (char *)[[args objectAtIndex:i] UTF8String];
    }

    int result = CompileObject(argc, argv);
    
    free(argv);
    
    return result;
}

@end
