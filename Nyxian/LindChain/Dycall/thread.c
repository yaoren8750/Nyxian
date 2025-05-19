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

#include <dlfcn.h>
#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include "thread.h"

/**
 * @brief This function seperates the main symbol behaviour of the dybinary and the binary
 *
 * We use this as a exitloop bypass
 */
void *threadripper(void *arg)
{
    // Getting the arguments passed to the thread by assumingly dyexec()
    dyargs *data = (dyargs *)arg;
    void *handle = data->handle;

    // Getting the main symbol of the dylib by dynamic loader symbol
    int (*dylib_main)(int, char**) = dlsym(handle, "main");
    
    // Finding out of dynamic loader symbol found its main symbol
    if(!dylib_main) {
        fprintf(stderr, "[!] error: %s\n", dlerror());
        pthread_exit((void*)(intptr_t)-1);
    }
    
    // Finally, running the dylibs main symbol
    int status = dylib_main(data->argc, data->argv);

    // Returning the value returned by the dylibs main symbol
    pthread_exit((void*)(intptr_t)status);
}
