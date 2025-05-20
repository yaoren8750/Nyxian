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

#import <Foundation/Foundation.h>
#import <LogService/LogService.h>
#include <objc/runtime.h>

#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

#include "hooker.h"
#include "thread.h"

/**
 * @brief This function is for dybinary execution
 *
 */
int dyexec(NSString *dylibPath,
           NSArray *arguments)
{
    // The arguments for the thread to take in
    dyargs data;
    
    // Setting the handle in-case the dybinary is already loaded
    data.handle = dlopen([dylibPath UTF8String], RTLD_NOLOAD);
    
    // Checking if the handle of the thread args contains a valid memory address that points to a dybinary image
    if(!data.handle)
    {
        // Its not loaded into memory so we load is lazily into memory, lazy because it should not bother our currently available symbols
        data.handle = dlopen([dylibPath UTF8String], RTLD_LAZY);
        
        // If the handle is still not a valid memory address that points to a dybinary image we abort and return a error
        if (!data.handle) {
            ls_printf("[!] error: %s\n", dlerror());
            return -1;
        }
        
        // Hooking the dybinary image so it doesnt call some symbols and calls our own version of them such as preventing them to exit
        if(!hooker([dylibPath UTF8String]))
        {
            ls_printf("[!] hooker failed to hook dylib\n");
            return -1;
        }
    }

    // Preparing Argv for the dybinaries main symbol
    data.argc = (int)[arguments count] + 1;
    data.argv = (char **)malloc((data.argc + 1) * sizeof(char *));
    data.argv[0] = strdup([dylibPath UTF8String]);
    data.argv[data.argc] = NULL;
    for(int i = 1; i < data.argc; i++)
        data.argv[i] = strdup([arguments[i - 1] UTF8String]);

    // Here we utilitse the threadripper approach because usually a exit() call is no return. The hooker previously hooked it to call pthread_exit(0) which bypasses the resulting performance issues
    pthread_t thread;
    if(pthread_create(&thread, NULL, threadripper, (void *)&data) != 0) {
        ls_printf("[!] error creating thread\n");
        return 1;
    }
    
    // The status of the dybinary resulting by its main threads return value
    void *status = NULL;
    
    // Joining the thread the dybinary runs on to catch its return value
    pthread_join(thread, &status);

    // Closing the dybinary to release its static memory and get rid of it being loaded in memory
    dlclose(data.handle);

    // Releasing the memory containing the main symbols argv
    for(int i = 0; i < data.argc; i++)
        free(data.argv[i]);
    free(data.argv);

    // Returning the status of the dybinary finally
    return (int)(intptr_t)status;
}

/**
 * @brief This function is for copied dybinary execution
 *
 * MARK: THIS IMPLEMENTATION IS UNFINISHED AND WILL BE USED LATER TO DEVELOP C CLI APP RUNNING, IN APP
 *
 */
NSString* invokeAppMain(NSString *selectedApp, NSString *selectedContainer, int argc, char *argv[]);
int LiveContainerMain(int argc, char *argv[]);
int dycpbexec(NSString *bundlePath,
              NSString *dylibPathInBundle)
{
    
    
    // First we copy over the bundle
    /*[[NSFileManager defaultManager] copyItemAtPath:bundlePath toPath:[NSString stringWithFormat:@"%@bundle", NSTemporaryDirectory()] error:NULL];
    
    // Now we try to open it up
    void *handle = dlopen([[NSString stringWithFormat:@"%@bundle%@", NSTemporaryDirectory(), dylibPathInBundle] UTF8String], RTLD_LAZY);
    
    printf("%p | %s", handle, dlerror());
    */
    
    // MARK: This is in testing
    NSString *tempDirectory = NSTemporaryDirectory();
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    NSArray *tempFiles = [fileManager contentsOfDirectoryAtPath:tempDirectory error:&error];

    if (error) {
        NSLog(@"Error getting contents of temp directory: %@", error.localizedDescription);
    } else {
        for (NSString *file in tempFiles) {
            NSString *filePath = [tempDirectory stringByAppendingPathComponent:file];
            BOOL success = [fileManager removeItemAtPath:filePath error:&error];
            if (!success || error) {
                NSLog(@"Failed to remove file at path %@: %@", filePath, error.localizedDescription);
            }
        }
    }
    
    [[NSFileManager defaultManager] copyItemAtPath:bundlePath toPath:[NSString stringWithFormat:@"%@bundle", NSTemporaryDirectory()] error:NULL];
    
    if(error)
        NSLog(@"error: %@", [error localizedDescription]);
    
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@bundle/Nyxian", NSTemporaryDirectory()] error:&error];
    
    if(error)
        NSLog(@"error: %@", [error localizedDescription]);
    
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@bundle/Frameworks/ld.dylib", NSTemporaryDirectory()] toPath:[NSString stringWithFormat:@"%@bundle/Nyxian", NSTemporaryDirectory()] error:&error];
    
    if(error)
        NSLog(@"error: %@", [error localizedDescription]);
    
    char *argv[1] = { "Nyxian" };
    
    //LiveContainerMain(1, argv);
    invokeAppMain(@"Nyxian", @"", 1, argv);
    
    return 0;
}
