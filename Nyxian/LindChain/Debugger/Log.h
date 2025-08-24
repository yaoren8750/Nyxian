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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdarg.h>
#include <sys/stat.h>


@interface LogContext : NSObject

@property (nonatomic,strong,readwrite) NSString *log;
@property (nonatomic,strong,readwrite) NSString *func;
@property (nonatomic,readwrite) UInt64 offset;

@end

void log_init(void);
void log_putc(char c);
void log_puts(const char *buf);
void log_putf(const char *fmt, ...);
void log_deinit(void);
void log_deinitCrash(uintptr_t crashAddr);
LogContext *logReadIfAvailable(void);
