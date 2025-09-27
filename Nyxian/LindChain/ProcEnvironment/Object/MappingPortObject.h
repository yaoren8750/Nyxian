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

#ifndef PROCENVIRONMENT_MAPPINGPORTOBJECT_H
#define PROCENVIRONMENT_MAPPINGPORTOBJECT_H

/* ----------------------------------------------------------------------
 *  Environment API Headers
 * -------------------------------------------------------------------- */
#import <LindChain/ProcEnvironment/Object/MachPortObject.h>

@interface MappingPortObject : MachPortObject

@property (nonatomic) vm_prot_t prot;
@property (nonatomic) size_t size;

- (instancetype)initWithAddr:(void*)addr withSize:(size_t)size withProt:(vm_prot_t)prot;

- (void*)map;
- (void*)mapAndDestroy;

@end

#endif /* PROCENVIRONMENT_MAPPINGPORTOBJECT_H */
