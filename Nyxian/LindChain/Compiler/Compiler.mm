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
int CompileObject(int argc,
                  const char **argv,
                  const char *platformTripple);

@interface Compiler ()

@property (nonatomic,strong) NSArray * _Nonnull flags;
@property (nonatomic,strong) NSLock *lock;

@end

@implementation Compiler

///
/// Method that initilizes the more-use Compiler
///
- (instancetype)init:(NSArray*)flags
{
    self = [super init];
    _flags = [flags copy];
    self.lock = [[NSLock alloc] init];
    
    return self;
}

///
/// Method that compiles a object file for a given file path
///
- (int)compileObject:(nonnull NSString*)filePath
      platformTriple:(NSString*)platformTriple
{
    // Securing the concurrency
    [self.lock lock];
    
    // Allocating the NSMutableArray with the file that is targetted for the compilation and add the flags previously given to the array
    NSMutableArray<NSString *> *args = [NSMutableArray arrayWithArray:@[
        @"clang",
        [filePath copy]
    ]];
    [args addObjectsFromArray:_flags];
    
    // Allocating a C array by the given NSMutableArray
    const int argc = (int)[args count];
    char **argv = (char **)malloc(sizeof(char*) * argc);
    for(int i = 0; i < argc; i++) argv[i] = strdup([[args objectAtIndex:i] UTF8String]);
    
    // Letting compilation run concurrent
    [self.lock unlock];

    // Compile and get the resulting integer
    const int result = CompileObject(argc, (const char**)argv, [platformTriple UTF8String]);
    
    // Securing the concurrency
    [self.lock lock];
    
    // Deallocating the entire C array
    for(int i = 0; i < argc; i++) free(argv[i]);
    free(argv);
    
    // Letting the resulting integer return concurrent
    [self.lock unlock];
    
    return result;
}

@end
