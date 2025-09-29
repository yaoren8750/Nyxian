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

#import <LindChain/ProcEnvironment/Object/FileObject.h>
#include <unistd.h>
#include <sys/stat.h>
#include <copyfile.h>

@implementation FileObject

- (instancetype)initWithPath:(NSString*)path
{
    self = [super init];
    _fd = open([path UTF8String], O_RDWR);
    return self;
}

- (BOOL)writeOut:(NSString *)path
{
    // Create destination or truncate it
    int dstFd = open([path UTF8String], O_RDWR | O_TRUNC | O_CREAT, 0777);
    if(dstFd == -1) return NO;
    
    // Now write
    int ret = fcopyfile(_fd, dstFd, NULL, COPYFILE_DATA);
    if(ret == -1) return NO;
    
    // And close dstFd
    ret = close(dstFd);
    if(ret == -1) return NO;
    return YES;
}

- (BOOL)writeIn:(NSString *)path
{
    // Open up src
    int srcFd = open([path UTF8String], O_RDWR);
    if(srcFd == -1) return NO;
    
    // Now write
    int ret = fcopyfile(srcFd, _fd, NULL, COPYFILE_DATA);
    if(ret == -1) return NO;
    
    // And close srcFd
    ret = close(srcFd);
    if(ret == -1) return NO;
    return YES;
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder
{
    if([coder respondsToSelector:@selector(encodeXPCObject:forKey:)])
    {
        xpc_object_t dict = xpc_dictionary_create(NULL, NULL, 0);
        xpc_dictionary_set_fd(dict, "fd", _fd);
        [(id)coder encodeXPCObject:dict forKey:@"fd"];
    }
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
{
    self = [super init];
    if([coder respondsToSelector:@selector(decodeXPCObjectOfType:forKey:)])
    {
        struct _xpc_type_s *dictType = (struct _xpc_type_s *)XPC_TYPE_DICTIONARY;
        NSObject<OS_xpc_object> *obj = [(id)coder decodeXPCObjectOfType:dictType
                                                                 forKey:@"fd"];
        if(obj)
        {
            _fd = xpc_dictionary_dup_fd(obj, "fd");
        }
        
    }
    return self;
}

@end
