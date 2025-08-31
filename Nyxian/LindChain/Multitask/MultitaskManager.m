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

//#import <LindChain/Private/FoundationPrivate.h>
#import <LindChain/Multitask/MultitaskManager.h>
#import <../LiveProcess/serverDelegate.h>
#import <LindChain/LiveContainer/UIKitPrivate.h>
#import <LindChain/Multitask/AppSceneViewController.h>
#import <LindChain/Multitask/DecoratedAppSceneViewController.h>

@interface PassthroughWindow : UIWindow
@end

@implementation PassthroughWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    /*UIView *hitView = [super hitTest:point withEvent:event];

    // If hitView is the root view controller's view (background), return nil
    if (hitView == self.rootViewController.view) {
        return nil;
    }
    // If hitView is nil, also return nil
    return hitView;*/
    return nil;
}
@end

pid_t proc_spawn_ios(NSString *windowTitle)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        static PassthroughWindow *overlayWindow = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            overlayWindow = [[PassthroughWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            overlayWindow.windowLevel = UIWindowLevelAlert + 1000; // Higher than normal alerts
            [[[UIApplication sharedApplication] keyWindow] addSubview:overlayWindow];
            [overlayWindow makeKeyAndVisible];
        });
        
        DecoratedAppSceneViewController *decoratedAppSceneViewController = [[DecoratedAppSceneViewController alloc] initWindowName:windowTitle];
        [overlayWindow addSubview:decoratedAppSceneViewController.view];
    });
    
    return 0;
}
