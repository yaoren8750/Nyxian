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
#import <Synpush/Synitem.h>
#include <clang-c/Index.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

///
/// Created this to co-op with the code editor
///
@interface SynpushServer : NSObject

///
/// Properties
///

// file path where the file is saved with the unsaved changes
@property (nonatomic,readonly,strong) NSString *filepath;

// the args you specified in project settings
@property (nonatomic,readonly) int argc;
@property (nonatomic,readonly) char **args;

// the CXIndex is like the main deal, the thing that is needed for all libclang actions
@property (nonatomic,readonly) CXIndex index;

// Now the unsaved file
@property (nonatomic,readonly) struct CXUnsavedFile file;

// the translation unit
@property (nonatomic,readonly) CXTranslationUnit unit;

// mutex to prevent the server from deinitilizing while resources are being used
@property (nonatomic,readonly) pthread_mutex_t mutex;

///
/// Functions
///
- (instancetype)init:(NSString*)filepath
                args:(NSArray*)args;

- (void)reparseFile:(NSString*) content;
- (NSArray<Synitem *> *)getDiagnostics;

- (void)deinit;

@end
