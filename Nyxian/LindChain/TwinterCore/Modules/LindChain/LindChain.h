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

#ifndef NYXIAN_MODULE_LINDCHAIN_H
#define NYXIAN_MODULE_LINDCHAIN_H

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

/*
 @Brief JSExport Protocol for TimerModule
 */
@protocol LindChainModuleExport <JSExport>

@end

/*
 @Brief TimerModule Module Interface
 */
@interface LindChainModule: NSObject <LindChainModuleExport>

@end

#endif /* NYXIAN_MODULE_TIMER_H */
