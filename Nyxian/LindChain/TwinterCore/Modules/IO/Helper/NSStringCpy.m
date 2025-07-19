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

#import <TwinterCore/Modules/IO/Helper/NSStringCpy.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char* NSStringCpy(NSString *nsstring)
{
    const char *ro_buffer = [nsstring UTF8String];
    size_t size_of_ro_buffer = strlen(ro_buffer);
    char *rw_buffer = malloc(size_of_ro_buffer);
    memcpy(rw_buffer, ro_buffer, size_of_ro_buffer);
    return rw_buffer;
}
