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

#ifndef NYXIAN_RUNTIME_H
#define NYXIAN_RUNTIME_H

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <UIKit/UIKit.h>
#include <pthread.h>

/// Header for Module Object type
#import <TwinterCore/Modules/Module.h>

NS_ASSUME_NONNULL_BEGIN

/*
 @Brief Interface of the Nyxian runtime
 */
@interface NYXIAN_Runtime : NSObject

@property (nonatomic,strong,readonly) JSContext *Context;

/// Main Runtime functions you should focus on
- (instancetype)init;
- (void)run:(NSString*)path;
- (void)cleanup;

/// Module Handoff functions
- (void)handoffModule:(Module*)module;

/// Is module already imported?
- (BOOL)isModuleImported:(NSString *)name;

@end

NS_ASSUME_NONNULL_END

#endif
