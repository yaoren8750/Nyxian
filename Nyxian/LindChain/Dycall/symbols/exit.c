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
#include <pthread.h>

/**
 * @brief This function holds the function pointer specified by a dybinary using atexit()
 *
 */
typedef void (*atexit_func)(void);
atexit_func registered_func = NULL;

/**
 * @brief This function is not meant to be called. Its our own implementation of the function for our hooker
 *
 */
void dy_atexit(atexit_func func)
{
    registered_func = func;
}

/**
 * @brief This function is not meant to be called. Its our own implementation of the function for our hooker
 *
 */
void dy_exit(int status)
{
    if (registered_func) {
        registered_func();
    }

    pthread_exit((void*)(intptr_t)status);
}
