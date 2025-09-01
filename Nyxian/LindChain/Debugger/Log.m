/*
 Copyright (C) 2025 cr4zyengineer

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

#import <LindChain/Debugger/Log.h>
#include <dlfcn.h>
#include "Utils.h"

@implementation LogContext
@end

static int destination_file_descriptor = -1;

/*
 Private
 */
static const char *log_init_logDocumentPath(void)
{
    // Holder for document path
    static char logDocumentPath[512];
    
    // Singleton
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        off_t offset = sprintf(logDocumentPath, "%s", [NSHomeDirectory() UTF8String]);
        snprintf(logDocumentPath + offset, 120 - offset, "%s", "/Documents/crash.txt");
    });
    
    return logDocumentPath;
}

static void log_init_open_fd(const char *path)
{
    destination_file_descriptor = open(path, O_RDWR | O_CREAT | O_TRUNC, 0777);
}

/*
 Public
 */
void log_init(void)
{
    if(destination_file_descriptor != -1) return;
    const char *logDocumentPath = log_init_logDocumentPath();
    log_init_open_fd(logDocumentPath);
}

void log_putc(char c)
{
    write(destination_file_descriptor, &c, 1);
}

void log_puts(const char *buf)
{
    size_t size = strlen(buf);
    write(destination_file_descriptor, buf, size);
}

void log_putf(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);

    va_list args_copy;
    va_copy(args_copy, args);
    int n = vsnprintf(NULL, 0, fmt, args_copy);
    va_end(args_copy);

    if (n < 0) {
        va_end(args);
        return;
    }

    char *buffer = malloc(n + 1);
    if (!buffer) {
        va_end(args);
        return; // allocation failed
    }

    vsnprintf(buffer, n + 1, fmt, args);
    va_end(args);

    write(destination_file_descriptor, buffer, n);

    free(buffer);
}

void log_deinitCrash(uintptr_t crashAddr)
{
    // Get symbol information
    Dl_info info;
    dladdr((void*)crashAddr, &info);
    
    uint64_t offset = crashAddr - (uintptr_t)info.dli_saddr;
    
    // Write info
    char nullTermination = '\0';
    write(destination_file_descriptor, &nullTermination, 1);
    dprintf(destination_file_descriptor, "%s", info.dli_sname);
    write(destination_file_descriptor, &nullTermination, 1);
    write(destination_file_descriptor, &offset, sizeof(uint64_t));
    close(destination_file_descriptor);
}

void log_deinitCrashLazy(const char *functionName,
                         off_t offset)
{
    // Write info
    char nullTermination = '\0';
    write(destination_file_descriptor, &nullTermination, 1);
    dprintf(destination_file_descriptor, "%s", functionName);
    write(destination_file_descriptor, &nullTermination, 1);
    write(destination_file_descriptor, &offset, sizeof(uint64_t));
    close(destination_file_descriptor);
}

void log_deinit(void)
{
    close(destination_file_descriptor);
}

LogContext *logReadIfAvailable(void)
{
    // Ensure no active log writing session
    if (destination_file_descriptor != -1) return NULL;

    // Construct log file path
    char logDocumentPath[PATH_MAX];
    off_t offset = sprintf(logDocumentPath, "%s", [NSHomeDirectory() UTF8String]);
    snprintf(logDocumentPath + offset, sizeof(logDocumentPath) - offset, "%s", "/Documents/crash.txt");

    // Open log file for reading
    int fd = open(logDocumentPath, O_RDONLY);
    if (fd < 0) return NULL;

    // Get file size
    struct stat fdstat;
    if (fstat(fd, &fdstat) < 0 || fdstat.st_size == 0) {
        close(fd);
        return NULL;
    }
    size_t bufferSize = fdstat.st_size;

    // Allocate and read buffer
    char *buffer = malloc(bufferSize);
    if (!buffer) {
        close(fd);
        return NULL;
    }
    read(fd, buffer, bufferSize);
    close(fd);

    // Create log context
    LogContext *logContext = [[LogContext alloc] init];

    // Parse format: [log string]\0[function name]\0[offset: uint64_t]
    char *ptr = buffer;
    char *end = buffer + bufferSize;

    // Extract log string
    size_t logLen = strlen(ptr/*, end - ptr*/); // MARK: WAS strlen before
    logContext.log = [[NSString alloc] initWithBytes:ptr length:logLen encoding:NSUTF8StringEncoding];
    ptr += logLen + 1; // Move past null terminator

    // Extract function name (if available)
    if (ptr < end) {
        size_t funcLen = strlen(ptr/*, end - ptr*/); // MARK: WAS strlen before
        logContext.func = [[NSString alloc] initWithBytes:ptr length:funcLen encoding:NSUTF8StringEncoding];
        ptr += funcLen + 1;
    }
    
    // Extract offset (if available)
    if (ptr + sizeof(uint64_t) <= end) {
        uint64_t loc = 0;
        memcpy(&loc, ptr, sizeof(uint64_t));
        logContext.offset = loc;
    } else {
        logContext.offset = 0;
    }

    // Clean up
    free(buffer);
    remove(logDocumentPath);

    // Return valid context if log has data
    return ([logContext.log length] == 0) ? nil : logContext;
}
