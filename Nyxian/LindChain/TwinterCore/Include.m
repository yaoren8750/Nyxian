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

/// Runtime Headers
#import <TwinterCore/Include.h>
#import <TwinterCore/ErrorThrow.h>

/// Module Headers
#import <TwinterCore/Modules/IO/IO.h>
#import <TwinterCore/Modules/Timer/Timer.h>

id NYXIAN_include(NYXIAN_Runtime *Runtime, NSString *LibName)
{
    // Placeholder for module to import
    Module *IncludeModule = NULL;
    
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
    [Runtime handoffModule:IncludeModule];
    
    return NULL;
}

void add_include_symbols(NYXIAN_Runtime *Runtime)
{
    __block NYXIAN_Runtime *BlockRuntime = Runtime;
    
    if (Runtime) {
        [Runtime.Context setObject:^id(NSString *LibName) {
            return NYXIAN_include(BlockRuntime, LibName);
        } forKeyedSubscript:@"include"];
    }
}
