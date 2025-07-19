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

#ifndef NYXIAN_MODULE_H
#define NYXIAN_MODULE_H

#import <Foundation/Foundation.h>

@interface Module : NSObject

@property (nonatomic,strong) dispatch_semaphore_t semaphore;

- (void)moduleCleanup;
- (dispatch_semaphore_t)giveSemaphore;

@end

#endif

