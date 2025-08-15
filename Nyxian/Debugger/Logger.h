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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface LogTextView : UITextView

@property (nonatomic,strong,readonly) NSPipe *pipe;
@property (nonatomic,strong,readonly) NSFileHandle *handle;

@end

@interface LoggerView : UIViewController

@property (nonatomic,strong,readonly) LogTextView *loggerText;

@end

@interface NyxianDebugger : NSObject

@property (nonatomic,readonly,strong) UIViewController *rootViewController;
@property (nonatomic,readwrite,strong) UIVisualEffectView *blurView;
@property (nonatomic,readwrite,strong) UINavigationController *loggerViewController;

- (void)attachGestureToWindow:(UIWindow*)keyWindow;
+ (NyxianDebugger*)shared;

@end
