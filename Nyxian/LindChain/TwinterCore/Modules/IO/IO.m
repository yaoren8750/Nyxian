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

/// Nyxian Runtime headers
#import <TwinterCore/Modules/IO/IO.h>
#import <TwinterCore/Modules/IO/Types/Stat.h>
#import <TwinterCore/Modules/IO/Types/DIR.h>
#import <TwinterCore/Modules/IO/Types/FILE.h>
#import <TwinterCore/Modules/IO/Types/Dirent.h>
#import <TwinterCore/ReturnObjBuilder.h>
#import <TwinterCore/ErrorThrow.h>

/// Some standard headers we need
#include <errno.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>

char* readline(const char *prompt);

/*
 @Brief I/O Module Implementation
 */
@implementation IOModule

- (instancetype)init
{
    self = [super init];
    _array = [[NSMutableArray alloc] init];
    return self;
}


///
/// These functions are the basic standard for Nyxian Runtime.
/// They are for the purpose to communicate with with the stdin
/// hook
///
- (NSString*)perror
{
    return @(strerror(errno));
}

- (id)fsync:(int)fd
{
    if(fsync(fd) == -1)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    return NULL;
}

- (id)ftruncate:(int)fd offset:(UInt64)offset
{
    if(ftruncate(fd, offset) == -1)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    return NULL;
}

///
/// These are basically macro redirections so Nyxian Runtime can
/// use these basic macros.
///
- (BOOL)S_ISDIR:(UInt64)m
{
    return S_ISDIR(m);
}

- (BOOL)S_ISREG:(UInt64)m
{
    return S_ISREG(m);
}

- (BOOL)S_ISLNK:(UInt64)m
{
    return S_ISLNK(m);
}

- (BOOL)S_ISCHR:(UInt64)m
{
    return S_ISCHR(m);
}

- (BOOL)S_ISBLK:(UInt64)m
{
    return S_ISBLK(m);
}

- (BOOL)S_ISFIFO:(UInt64)m
{
    return S_ISFIFO(m);
}

- (BOOL)S_ISSOCK:(UInt64)m
{
    return S_ISSOCK(m);
}

///
/// Functions for basic file descriptor I/O
///
- (id)open:(NSString *)path withFlags:(int)flags perms:(UInt16)perms {
    int fd = -1;

    if(perms == 0)
        perms = 0777;
    
    fd = open([path UTF8String], flags, perms);
    
    if (fd == -1)
        return JS_THROW_ERROR(EW_UNEXPECTED);

    return [[NSNumber alloc] initWithInt:fd];
}

- (id)close:(int)fd
{
    if(close(fd) == -1)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    return NULL;
}

- (id)write:(int)fd text:(NSString*)text size:(UInt64)size
{
    if(size == 0)
        return JS_THROW_ERROR(EW_INVALID_INPUT);
    
    const char *buffer = [text UTF8String];
    
    if(text.length < size)
        return JS_THROW_ERROR(EW_OUT_OF_BOUNDS);
    
    ssize_t bytesWritten = write(fd, buffer, size);
    
    if (bytesWritten < 0)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    return @(bytesWritten);
}

- (id)read:(int)fd size:(UInt64)size
{
    if(size == 0)
        return JS_THROW_ERROR(EW_INVALID_INPUT);
    
    char *rw_buffer = malloc(size);
    
    if(rw_buffer == NULL)
        return JS_THROW_ERROR(EW_NULL_POINTER);
    
    ssize_t bytesRead = read(fd, rw_buffer, size);

    if (bytesRead == 0)
        return NULL;
    
    NSData *resultData = [NSData dataWithBytes:rw_buffer length:bytesRead];
    
    NSString *resultString = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    
    if(resultString == nil)
        return JS_THROW_ERROR(EW_NULL_POINTER);
    
    return ReturnObjectBuilder(@{
        @"bytesRead": @(bytesRead),
        @"buffer": resultString,
    });
}

- (id)stat:(int)fd
{
    struct stat statbuf;
    
    if (fstat(fd, &statbuf) < 0)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    return buildStat(statbuf);
}

- (id)seek:(int)fd position:(UInt16)position flags:(int)flags
{
    if(lseek(fd, position, flags) == -1)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    return NULL;
}

- (id)access:(NSString*)path flags:(int)flags
{
    return [[NSNumber alloc] initWithInt: access([path UTF8String], flags)];
}

- (id)remove:(NSString*)path
{
    if (remove([path UTF8String]) != 0)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    return NULL;
}

- (id)mkdir:(NSString*)path perms:(UInt16)perms
{
    if(perms == 0)
        perms = 0777;
    
    if(mkdir([path UTF8String], (mode_t)perms) != 0)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    return NULL;
}

- (id)rmdir:(NSString*)path
{
    if(rmdir([path UTF8String]) != 0)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    return NULL;
}

- (id)chown:(NSString*)path uid:(int)uid gid:(int)gid
{
    if(chown([path UTF8String], uid, gid) != 0)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    return NULL;
}

- (id)chmod:(NSString*)path flags:(UInt16)flags
{
    if(chmod([path UTF8String], (mode_t)flags) != 0)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    return NULL;
}

- (id)chdir:(NSString*)path
{
    if(chdir([path UTF8String]) != 0)
        return JS_THROW_ERROR(EW_PERMISSION);
    
    return NULL;
}

///
/// This is still work in progress, these symbols are to interact with
/// file pointers.
///
- (id)fopen:(NSString*)path mode:(NSString*)mode
{
    FILE *file = fopen([path UTF8String], [mode UTF8String]);
    
    if(file == NULL)
        return JS_THROW_ERROR(EW_NULL_POINTER);

    int fd = fileno(file);

    if(fd == -1)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    return buildFILE(file);
}

- (id)fclose:(JSValue*)fileObject
{
    if(fileObject == NULL)
        return JS_THROW_ERROR(EW_INVALID_INPUT);
    
    FILE *file = restoreFILE(fileObject);
    
    if(file == NULL)
        return JS_THROW_ERROR(EW_NULL_POINTER);
    
    int fd = fileno(file);
    
    if(fd == -1)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    if(fclose(file) != 0)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    updateFILE(file, fileObject);
    
    return NULL;
}

- (id)freopen:(NSString*)path mode:(NSString*)mode fileObject:(JSValue*)fileObject
{
    if(fileObject == NULL)
        return JS_THROW_ERROR(EW_INVALID_INPUT);
    
    FILE *file = restoreFILE(fileObject);
    
    if(file == NULL)
        return JS_THROW_ERROR(EW_NULL_POINTER);
    
    int fd = fileno(file);
    
    FILE *reopenedfile = freopen([path UTF8String], [mode UTF8String], file);
    
    if (reopenedfile == NULL)
        return JS_THROW_ERROR(EW_NULL_POINTER);
    
    int reopenedfd = fileno(reopenedfile);
    
    if(reopenedfd == -1)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    updateFILE(reopenedfile, fileObject);
    
    return fileObject;
}

- (id)fileno:(JSValue*)fileObject
{
    if(fileObject == NULL)
        return JS_THROW_ERROR(EW_INVALID_INPUT);
    
    FILE *file = restoreFILE(fileObject);
    
    if(file == NULL)
        return JS_THROW_ERROR(EW_NULL_POINTER);
    
    int fd = fileno(file);
    
    if(fd == -1)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    return @(fd);
}

///
/// Functions for basic directory I/O
///
- (id)opendir:(NSString*)path
{
    DIR *directory = opendir([path UTF8String]);
    
    if(directory == NULL)
        return JS_THROW_ERROR(EW_NULL_POINTER);
    
    return buildDIR(directory);
}

- (id)closedir:(JSValue*)DIR_obj
{
    if(DIR_obj == NULL)
        return JS_THROW_ERROR(EW_INVALID_INPUT);
    
    DIR *directory = buildBackDIR(DIR_obj);
    
    if (directory == NULL)
        return JS_THROW_ERROR(EW_NULL_POINTER);
    
    int fd = directory->__dd_fd;
    
    if(fd == -1)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    if (closedir(directory) != 0)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    return NULL;
}

- (id)readdir:(JSValue*)DIR_obj
{
    if(DIR_obj == NULL)
        return JS_THROW_ERROR(EW_INVALID_INPUT);
    
    DIR *directory = buildBackDIR(DIR_obj);
    
    if (directory == NULL)
        return JS_THROW_ERROR(EW_NULL_POINTER);

    int fd = directory->__dd_fd;
    
    if(fd == -1)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    struct dirent *result = readdir(directory);

    if (result == NULL)
        return JS_THROW_ERROR(EW_NULL_POINTER);

    updateDIR(directory, DIR_obj);

    return buildDirent(*result);
}

- (id)rewinddir:(JSValue*)DIR_obj
{
    if(DIR_obj == NULL)
        return JS_THROW_ERROR(EW_INVALID_INPUT);
    
    DIR *directory = buildBackDIR(DIR_obj);
    
    if (directory == NULL)
        return JS_THROW_ERROR(EW_NULL_POINTER);

    int fd = directory->__dd_fd;
    
    if(fd == -1)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    rewinddir(directory);
    
    updateDIR(directory, DIR_obj);

    return NULL;
}

///
/// Functions to deal with environment variables
///
- (id)getenv:(NSString*)env
{
    const char *env_value = getenv([env UTF8String]);
    
    if(!env_value)
        return JS_THROW_ERROR(EW_NULL_POINTER);
    
    return @(env_value);
}

- (id)setenv:(NSString*)env value:(NSString*)value overwrite:(UInt32)overwrite
{
    if(setenv([env UTF8String], [value UTF8String], overwrite) != 0)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    return NULL;
}

- (id)unsetenv:(NSString*)env
{
    if(unsetenv([env UTF8String]) != 0)
        return JS_THROW_ERROR(EW_UNEXPECTED);
    
    return NULL;
}

- (id)getcwd:(UInt64)size
{
    if(size == 0)
        size = PATH_MAX;
    
    char rw_buffer[size];
    
    if(getcwd(rw_buffer, size) == NULL)
    {
        return JS_THROW_ERROR(EW_NULL_POINTER);
    }
    
    return @(rw_buffer);
}

@end
