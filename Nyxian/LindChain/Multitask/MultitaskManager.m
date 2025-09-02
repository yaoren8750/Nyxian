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

#import <LindChain/Multitask/MultitaskManager.h>

@implementation LDEMultitaskManager

- (instancetype)init
{
    _windows = [[NSMutableArray alloc] init];
    return [super init];
}

+ (LDEMultitaskManager*)shared
{
    static LDEMultitaskManager *multitaskManagerSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        multitaskManagerSingleton = [[LDEMultitaskManager alloc] init];
    });
    return multitaskManagerSingleton;
}

- (DecoratedAppSceneViewController*)windowForBundleID:(NSString*)bundleID
{
    for(DecoratedAppSceneViewController *window in self.windows) if([window.appSceneVC.appObj.bundleIdentifier isEqual:bundleID]) return window;
    return nil;
}

- (BOOL)openApplicationWithBundleID:(NSString*)bundleID
{
    return [self openApplicationWithBundleID:bundleID terminateIfRunning:NO];
}

- (BOOL)openApplicationWithBundleID:(NSString*)bundleID
                 terminateIfRunning:(BOOL)terminate
{
    DecoratedAppSceneViewController *existingWindow = [self windowForBundleID:bundleID];
    if(existingWindow)
    {
        if(terminate)
            [existingWindow.appSceneVC restart];
        else
            [self.targetView bringSubviewToFront:existingWindow.view];
        return YES;
    }

    __block BOOL result = NO;
    void (^workBlock)(void) = ^{
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes)
            {
                if ([scene isKindOfClass:[UIWindowScene class]])
                {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    for (UIWindow *w in windowScene.windows)
                    {
                        if (w.isKeyWindow)
                        {
                            self.targetView = w;
                            break;
                        }
                    }
                }
            }
        });
        
        // If looking for it failed, return
        if (!self.targetView)
        {
            result = NO;
            return;
        }
        
        // Go!
        DecoratedAppSceneViewController *decoratedAppSceneViewController = [[DecoratedAppSceneViewController alloc] initWithBundleID:bundleID];
        [self.targetView addSubview:decoratedAppSceneViewController.view];
        [self.windows addObject:decoratedAppSceneViewController];
        result = YES;
    };

    if ([NSThread isMainThread])
        workBlock();
    else
        dispatch_sync(dispatch_get_main_queue(), workBlock);

    return result;
}

- (void)bringWindowToFrontWithBundleID:(NSString*)bundleID
{
    DecoratedAppSceneViewController *existingWindow = [self windowForBundleID:bundleID];
    if(existingWindow)
    {
        [self.targetView bringSubviewToFront:existingWindow.view];
        return;
    }
}

- (void)terminateApplicationWithBundleID:(NSString*)bundleID
{
    DecoratedAppSceneViewController *window = [self windowForBundleID:bundleID];;
    if(window) [window closeWindow];
}

- (void)removeWindowObject:(DecoratedAppSceneViewController*)window
{
    [self.windows removeObject:window];
}

@end
