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

/// Runtime headers
#import <TwinterCore/Runtime.h>
#import <TwinterCore/Include.h>
#import <TwinterCore/EnvRecover.h>
#import <LogService/LogService.h>
#import <Nyxian-Swift.h>

/*
 @Brief Nyxian runtime extension
 */
@interface NYXIAN_Runtime ()

@property (nonatomic,strong) NSMutableArray<Module*> *array;
@property (nonatomic,strong) EnvRecover *envRecover;

@end

/*
 @Brief Nyxian runtime implementation
 */
@implementation NYXIAN_Runtime

- (instancetype)init
{
    self = [super init];
    _Context = [[JSContext alloc] init];
    _envRecover = [[EnvRecover alloc] init];
    _array = [[NSMutableArray alloc] init];
    return self;
}

/// Main Runtime function to execute code
- (void)run:(NSString*)path
{
    // Creating a backup of the current envp
    [_envRecover createBackup];
    
    // Gathering code from the file
    NSString *code = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    
    // Changing current work directory
    NSURL *url = [[NSURL fileURLWithPath:path] URLByDeletingLastPathComponent];
    chdir([[url path] UTF8String]);
    
    // Setting environment up to be safe
    add_include_symbols(self);
    
    // Setting up and running the code in the environment
    _Context.exceptionHandler = ^(JSContext *context, JSValue *exception) {
        ls_printf("%s", [[NSString stringWithFormat:@"\nNyxian %@", exception] UTF8String]);
    };
    [_Context evaluateScript:code];
    
    // Cleaning up mess in case
    [self cleanup];
}

/// Private cleanup function
- (void)cleanup
{
    // We run each modules cleanup function
    for (id item in _array) {
        [item moduleCleanup];
    }
    
    // And we remove all modules from the array
    [_array removeAllObjects];
    
    // And here we get fake stdout
    ls_printf("[EXIT]\n");
    
    // And we tell ARC that ARC can fuck them selves and release the Context
    _Context = nil;
    
    [_envRecover restoreBackup];
}

/// Module check
///
/// In case someone tries to include the same module twice
- (BOOL)isModuleImported:(NSString *)name
{
    JSValue *module = [_Context objectForKeyedSubscript:name];
    return !module.isUndefined && !module.isNull;
}

/// Module Handoff function
///
/// Function to handoff a module that has extra cleanup work todo
- (void)handoffModule:(Module*)module
{
    [_array addObject:module];
}

@end
