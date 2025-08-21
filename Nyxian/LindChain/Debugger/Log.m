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

#import <Debugger/Log.h>

static int destination_file_descriptor = 0;

void log_init(void)
{
    if(destination_file_descriptor != 0) return;
    char logDocumentPath[120];
    off_t offset = sprintf(logDocumentPath, "%s", [NSHomeDirectory() UTF8String]);
    snprintf(logDocumentPath + offset, 120 - offset, "%s", "/Documents/crash.txt");
    destination_file_descriptor = open(logDocumentPath, O_WRONLY | O_CREAT | O_TRUNC, 0777);
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
    char buffer[1024];
    va_list args;
    va_start(args, fmt);
    int n = vsnprintf(buffer, sizeof(buffer), fmt, args);
    va_end(args);

    if (n > 0) {
        write(destination_file_descriptor, buffer, n);
    }
}

void log_deinit(void)
{
    close(destination_file_descriptor);
}

NSString *logReadIfAvailable(void)
{
    // Open up
    if(destination_file_descriptor != 0) return NULL;
    char logDocumentPath[120];
    off_t offset = sprintf(logDocumentPath, "%s", [NSHomeDirectory() UTF8String]);
    snprintf(logDocumentPath + offset, 120 - offset, "%s", "/Documents/crash.txt");
    destination_file_descriptor = open(logDocumentPath, O_RDONLY);
    
    // Read raw buffer
    struct stat fdstat;
    fstat(destination_file_descriptor, &fdstat);
    size_t bufferSize = fdstat.st_size;
    printf("%zu bytes long!\n", bufferSize);
    char *buffer = malloc(bufferSize);
    read(destination_file_descriptor, buffer, bufferSize);
    
    // Convert into NSString
    NSString *result = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    
    // Releasing buffer
    free(buffer);
    
    close(destination_file_descriptor);
    
    remove(logDocumentPath);
    
    // Return log buffer
    return ([result length] == 0) ? NULL : result;
}
