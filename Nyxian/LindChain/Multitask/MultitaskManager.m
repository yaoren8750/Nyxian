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
    self = [super init];
    _windowGroups = [[NSMutableDictionary alloc] init];
    return self;
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

- (BOOL)openApplicationWithBundleIdentifier:(NSString*)bundleIdentifier
{
    return [self openApplicationWithBundleIdentifier:bundleIdentifier terminateIfRunning:NO];
}

- (BOOL)openApplicationWithBundleIdentifier:(NSString*)bundleIdentifier
                         terminateIfRunning:(BOOL)terminate
{
    DecoratedAppSceneViewController *existingWindow = [self mainWindowForBundleIdentifier:bundleIdentifier];
    if(existingWindow)
    {
        if(terminate)
            [existingWindow restart];
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
        DecoratedAppSceneViewController *decoratedAppSceneViewController = [[DecoratedAppSceneViewController alloc] initWithBundleID:bundleIdentifier];
        [self.targetView addSubview:decoratedAppSceneViewController.view];
        NSMutableArray<DecoratedAppSceneViewController*> *windowGroup = [[NSMutableArray alloc] init];
        [windowGroup addObject:decoratedAppSceneViewController];
        [self.windowGroups setObject:windowGroup forKey:bundleIdentifier];
        result = YES;
    };

    if ([NSThread isMainThread])
        workBlock();
    else
        dispatch_sync(dispatch_get_main_queue(), workBlock);

    return result;
}

- (void)closeApplicationWithBundleIdentifier:(NSString*)bundleIdentifier
{
    NSMutableArray<DecoratedAppSceneViewController*> *windowGroup = [self windowGroupForBundleIdentifier:bundleIdentifier];;
    if(windowGroup) for(DecoratedAppSceneViewController *window in windowGroup) [window closeWindow];
    [self.windowGroups removeObjectForKey:bundleIdentifier];
}

- (NSMutableArray<DecoratedAppSceneViewController*>*)windowGroupForBundleIdentifier:(NSString*)bundleIdentifier
{
    for(NSString *key in self.windowGroups) if([key isEqualToString:bundleIdentifier]) return self.windowGroups[key];
    return nil;
}

- (DecoratedAppSceneViewController*)mainWindowForBundleIdentifier:(NSString*)bundleIdentifier
{
    return [[self windowGroupForBundleIdentifier:bundleIdentifier] firstObject];
}

- (void)bringWindowGroupToFrontWithBundleIdentifier:(NSString*)bundleIdentifier
{
    NSMutableArray<DecoratedAppSceneViewController*> *windowGroup = [self windowGroupForBundleIdentifier:bundleIdentifier];
    if(windowGroup) for(DecoratedAppSceneViewController *window in windowGroup) [self.targetView bringSubviewToFront:window.view];
}

@end
