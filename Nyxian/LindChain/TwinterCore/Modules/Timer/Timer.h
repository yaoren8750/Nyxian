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

#ifndef NYXIAN_MODULE_TIMER_H
#define NYXIAN_MODULE_TIMER_H

#import <TwinterCore/Modules/Module.h>
#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

/*
 @Brief JSExport Protocol for TimerModule
 */
@protocol TimerModuleExport <JSExport>

/// Better way to sleep than sleep :3
- (void)wait:(double)seconds;

@end

/*
 @Brief TimerModule Module Interface
 */
@interface TimerModule: Module <TimerModuleExport>

@end

#endif /* NYXIAN_MODULE_TIMER_H */
