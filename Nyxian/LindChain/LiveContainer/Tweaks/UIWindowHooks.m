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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "../Debugger/Logger.h"
#import <ObjC/Swizzle.h>

@implementation UIWindow(LiveContainer)

- (void)lc_makeKeyAndVisible
{
    [self lc_makeKeyAndVisible];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NyxianDebugger shared] attachGestureToWindow:self];
    });
}

@end

void UIWindowHooksInit(void)
{
    [ObjCSwizzler replaceInstanceAction:@selector(lc_makeKeyAndVisible) ofClass:UIWindow.class withAction:@selector(makeKeyAndVisible)];
}
