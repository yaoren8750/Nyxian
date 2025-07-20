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
#import <TwinterCore/EnvRecover.h>
#import <LogService/LogService.h>
#import <Nyxian-Swift.h>
#import <TwinterCore/ErrorThrow.h>

/// Module Headers
#import <TwinterCore/Modules/IO/IO.h>
#import <TwinterCore/Modules/Timer/Timer.h>
#import <TwinterCore/Modules/LindChain/LindChain.h>

/*
 @Brief Nyxian runtime extension
 */
@interface NYXIAN_Runtime ()

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
    __block NYXIAN_Runtime *Runtime = self;
    [_Context setObject:^id(NSString *LibName) {
        // Placeholder for module to import
        NSObject *IncludeModule = NULL;
        
        // Checking if module with that name is already imported
        if([Runtime isModuleImported:LibName])
        {
            return NULL;
        }
        
        if ([LibName isEqualToString:@"IO"]) {
            IO_MACRO_MAP();
            IncludeModule = [[IOModule alloc] init];
        } else if ([LibName isEqualToString:@"Timer"]) {
            IncludeModule = [[TimerModule alloc] init];
        } else if ([LibName isEqualToString:@"LindChain"]) {
            IncludeModule = [[LindChainModule alloc] init];
        } else {
            NSString *path = [NSString stringWithFormat:@"%@.nxm", LibName];
            NSURL *url = [[NSURL fileURLWithPath:path] URLByDeletingLastPathComponent];
            NSString *code = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
            NSString *currentPath = [[NSFileManager defaultManager] currentDirectoryPath];
            
            chdir([[url path] UTF8String]);
            
            NSString *realLibName = [[NSURL fileURLWithPath:LibName] lastPathComponent];
            
            if (!code) {
                return jsDoThrowError([NSString stringWithFormat:@"include: %@\n", EW_FILE_NOT_FOUND]);
            }
            
            [Runtime.Context evaluateScript:[NSString stringWithFormat:@"var %@ = (function() {\n%@}\n)();", realLibName, code]];
            
            JSValue *exception = Runtime.Context.exception;
            if (exception && !exception.isUndefined && !exception.isNull) {
                jsDoThrowError([NSString stringWithFormat:@"include: %@\n", [exception toString]]);
                Runtime.Context.exception = nil;
            }
            
            chdir([currentPath UTF8String]);
            
            return NULL;
        }
        
        // complete include
        if(!IncludeModule)
            return NULL;
        
        [Runtime.Context setObject:IncludeModule forKeyedSubscript:LibName];
        
        return NULL;
    } forKeyedSubscript:@"include"];
    
    // Setting up and running the code in the environment
    _Context.exceptionHandler = ^(JSContext *context, JSValue *exception) {
        ls_printf("%s", [[NSString stringWithFormat:@"\nNyxian %@", exception] UTF8String]);
    };
    [_Context evaluateScript:code];
    
    // Cleaning up mess in case
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

@end
