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

#ifndef FD_MAP_OBJECT_H
#define FD_MAP_OBJECT_H

#import <Foundation/Foundation.h>

@interface FDMapObject : NSObject <NSSecureCoding>

@property (nonatomic) NSMutableArray<NSObject<OS_xpc_object>*> *fd_map;

/// Copies the fd map of the current process
- (void)copy_fd_map;

/// Intended for a brand new process, overmapping the fd map
- (void)apply_fd_map;

@end

#endif /* FD_MAP_OBJECT_H */
