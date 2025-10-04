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

#import <LindChain/ProcEnvironment/Object/MappingPortObject.h>
#include <sys/mman.h>

kern_return_t mach_vm_map(
    vm_map_t                target,
    mach_vm_address_t      *address,
    mach_vm_size_t          size,
    mach_vm_offset_t        mask,
    int                     flags,
    mem_entry_name_port_t   object,
    memory_object_offset_t  offset,
    boolean_t               copy,
    vm_prot_t               cur_prot,
    vm_prot_t               max_prot,
    vm_inherit_t            inheritance
);

@implementation MappingPortObject

- (instancetype)initWithAddr:(void*)addr
                    withSize:(size_t)size
                    withProt:(vm_prot_t)prot
{
    memory_object_size_t entry_len = size;
    mach_port_t memport = MACH_PORT_NULL;
    
    kern_return_t kr = mach_make_memory_entry_64(mach_task_self(),
                                                 &entry_len,
                                                 (mach_vm_address_t)addr,
                                                 prot | MAP_MEM_VM_SHARE,
                                                 &memport,
                                                 MACH_PORT_NULL);
    
    if(kr != KERN_SUCCESS) return nil;
    
    self = [super initWithPort:memport];
    self.addr = addr;
    self.prot = prot;
    self.size = size;
    self.isMapped = YES;
    return self;
}

- (instancetype)initWithSize:(size_t)size
                    withProt:(vm_prot_t)prot
{
    void *addr = mmap(NULL, size, prot, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    return (addr == MAP_FAILED) ? nil : [self initWithAddr:addr withSize:size withProt:prot];
}

- (void*)map
{
    mach_vm_address_t addr = 0;
    kern_return_t kr = mach_vm_map(mach_task_self(),
                                   &addr,
                                   self.size,
                                   0,
                                   VM_FLAGS_ANYWHERE,
                                   self.port,
                                   0,
                                   FALSE,
                                   self.prot,
                                   self.prot,
                                   VM_INHERIT_NONE);
    if(kr != KERN_SUCCESS) return MAP_FAILED;
    return (void*)addr;
}

- (instancetype)copy
{
    return [self copyWithProt:_prot];
}

- (instancetype)copyWithProt:(vm_prot_t)prot
{
    return self.isMapped ? [[MappingPortObject alloc] initWithAddr:_addr withSize:_size withProt:prot] : nil;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:[NSNumber numberWithInt:_prot] forKey:@"prot"];
    [coder encodeObject:[NSNumber numberWithUnsignedLongLong:_size] forKey:@"size"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    self.prot = ((NSNumber*)[coder decodeObjectOfClass:[NSNumber class] forKey:@"prot"]).intValue;
    self.size = ((NSNumber*)[coder decodeObjectOfClass:[NSNumber class] forKey:@"size"]).unsignedLongLongValue;
    return self;
}

@end
