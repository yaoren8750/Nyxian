/*
 Copyright (C) 2025 Lindsey

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
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

#import <Foundation/Foundation.h>
#import <Nyxian-Swift.h>
#import "LogService.h"

///
/// Private API
///
int ls_getfd(void)
{
    return LDELogger.pipe.fileHandleForWriting.fileDescriptor;
}

///
/// Public API
///
void ls_putc(char c)
{
    int fd = ls_getfd();
    write(fd, &c, 1);
}

void ls_puts(const char *buf,
             size_t size)
{
    int fd = ls_getfd();
    write(fd, buf, size);
}

void ls_printf(const char *format, ...)
{
    va_list args;
    va_start(args, format);
    
    int fd = ls_getfd();
    
    for(const char *p = format; *p != '\0'; p++)
    {
        if (*p == '%' && *(p + 1)) {
            p++;
            switch (*p) {
                case 'd': {
                    int i = va_arg(args, int);
                    dprintf(fd, "%d", i);
                    break;
                }
                case 's': {
                    char *s = va_arg(args, char *);
                    dprintf(fd, "%s", s);
                    break;
                }
                case 'p': {
                    char *s = va_arg(args, char *);
                    dprintf(fd, "%p", s);
                    break;
                }
                case 'c': {
                    int c = va_arg(args, int);
                    ls_putc(c);
                    break;
                }
                default:
                    ls_putc('%');
                    ls_putc(*p);
                    break;
            }
        } else {
            putchar(*p);
        }
    }
    
    va_end(args);
}

void ls_nsprint(NSString *msg)
{
    ls_puts([msg UTF8String], [msg length]);
}
