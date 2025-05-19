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
    dyargs data;
    
    // Dont load if its already loaded
    data.handle = dlopen([dylibPath UTF8String], RTLD_NOLOAD);
    
    // If its not loaded yet then load it from that path
    if(!data.handle)
    {
        data.handle = dlopen([dylibPath UTF8String], RTLD_LAZY);
        
        if (!data.handle)
            return -1;
        
        if(!hooker([dylibPath UTF8String], data.handle))
            return -1;
        
        dlerror();
    }
    
    // If its still not loaded then abort
    if(!data.handle)
        return -1;

    // Prepare Argv for the dybinary
    data.argc = (int)[arguments count];
    data.argv = (char **)malloc((data.argc + 1) * sizeof(char *));
    for (int i = 0; i < data.argc; i++) {
        data.argv[i] = strdup([arguments[i] UTF8String]);
    }
    data.argv[data.argc] = NULL;

    // Threadripper approach to handle the exit() function call
    void *status = NULL;
    pthread_t thread;
    if (pthread_create(&thread, NULL, threadripper, (void *)&data) != 0) {
        ls_nsprint(@"[!] error creating thread\n");
        status = (void*)(intptr_t) -1;
    }
    pthread_join(thread, &status);
    
    // When the thread is done we close the handle
    dlclose(data.handle);

    // Now we free the memory argv needs
    for (int i = 0; i < data.argc; i++) free(data.argv[i]);
    free(data.argv);

    return (int)(intptr_t)status;
}
