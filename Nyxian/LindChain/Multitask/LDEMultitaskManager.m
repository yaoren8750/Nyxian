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

#import <LindChain/Multitask/LDEMultitaskManager.h>

@implementation LDEMultitaskManager

- (instancetype)init
{
    self = [super init];
    _windowGroups = [[NSMutableDictionary alloc] init];
    _windowDimensions = [[NSMutableDictionary alloc] init];
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
    return [self openApplicationWithBundleIdentifier:bundleIdentifier
                                  terminateIfRunning:NO
                                     enableDebugging:NO];
}

- (BOOL)openApplicationWithBundleIdentifier:(NSString*)bundleIdentifier
                         terminateIfRunning:(BOOL)terminate
                            enableDebugging:(BOOL)enableDebug
{
    NSMutableArray<LDEWindow*> *windowGroup = [self windowGroupForBundleIdentifier:bundleIdentifier];
    if(windowGroup)
    {
        LDEWindow *mainWindow = [windowGroup firstObject];
        if (terminate)
        {
            [windowGroup removeObjectAtIndex:0];
            for (LDEWindow *window in windowGroup)
            {
                NSString *key = [NSString stringWithFormat:@"%@.%@", bundleIdentifier, window.windowName];

                if (window.view) {
                    [self.windowDimensions setObject:[NSValue valueWithCGRect:window.view.frame]
                                              forKey:key];
                }

                [window closeWindow];
            }

            NSMutableArray<LDEWindow*> *newWindowGroup = [[NSMutableArray alloc] init];
            [newWindowGroup addObject:mainWindow];
            [self.windowGroups setObject:newWindowGroup forKey:bundleIdentifier];
            [mainWindow restart];
        }
        else
        {
            [self.targetView bringSubviewToFront:mainWindow.view];
        }
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
        NSString *mainKey = [NSString stringWithFormat:@"%@.main", bundleIdentifier];
        CGRect frame = CGRectMake(50, 150, 320, 480);
        NSValue *cachedFrame = [self.windowDimensions objectForKey:mainKey];
        if (cachedFrame) frame = cachedFrame.CGRectValue;
        
        LDEWindow *decoratedAppSceneViewController = [[LDEWindow alloc] initWithBundleID:bundleIdentifier
                                                                         enableDebugging:enableDebug
                                                                          withDimensions:frame];
        
        [self.targetView addSubview:decoratedAppSceneViewController.view];
        NSMutableArray<LDEWindow*> *windowGroup = [[NSMutableArray alloc] init];
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
    NSMutableArray<LDEWindow*> *windowGroup = [self windowGroupForBundleIdentifier:bundleIdentifier];
    if(windowGroup) {
        BOOL isFirst = YES;
        for(LDEWindow *window in windowGroup) {
            NSString *key;
            if (isFirst) {
                key = [NSString stringWithFormat:@"%@.main", bundleIdentifier];
                isFirst = NO;
            } else {
                key = [NSString stringWithFormat:@"%@.%@", bundleIdentifier, window.windowName];
            }

            if (window.view) {
                [self.windowDimensions setObject:[NSValue valueWithCGRect:window.view.frame]
                                          forKey:key];
            }

            [window closeWindow];
        }
    }
    [self.windowGroups removeObjectForKey:bundleIdentifier];
}


- (NSString*)bundleIdentifierForProcessIdentifier:(pid_t)processIdentifier
{
    for(NSString *key in self.windowGroups) {
        NSMutableArray<LDEWindow*> *windowGroup = self.windowGroups[key];
        LDEWindow *mainWindow = [windowGroup firstObject];
        if(mainWindow.appSceneVC.pid == processIdentifier)
        {
            return mainWindow.appSceneVC.appObj.bundleIdentifier;
        }
    }
    return nil;
}

- (NSMutableArray<LDEWindow*>*)windowGroupForBundleIdentifier:(NSString*)bundleIdentifier
{
    return [self.windowGroups objectForKey:bundleIdentifier];
}

- (LDEWindow*)mainWindowForBundleIdentifier:(NSString*)bundleIdentifier
{
    return [[self windowGroupForBundleIdentifier:bundleIdentifier] firstObject];
}

- (void)bringWindowGroupToFrontWithBundleIdentifier:(NSString*)bundleIdentifier
{
    NSMutableArray<LDEWindow*> *windowGroup = [self windowGroupForBundleIdentifier:bundleIdentifier];
    if(windowGroup) for(LDEWindow *window in windowGroup) [self.targetView bringSubviewToFront:window.view];
}

- (void)attachView:(UIView*)view toWindowGroupOfBundleIdentifier:(NSString*)bundleIdentifier withTitle:(NSString*)title
{
    NSMutableArray<LDEWindow*> *windowGroup = [self windowGroupForBundleIdentifier:bundleIdentifier];
    LDEWindow *mainWindow = [windowGroup firstObject];
    if(windowGroup) {
        NSString *actualTitle = [NSString stringWithFormat:@"%@ - %@", mainWindow.appSceneVC.appObj.displayName, title];
        NSString *key = [NSString stringWithFormat:@"%@.%@", bundleIdentifier, actualTitle];
        CGRect frame = CGRectMake(50, 150, 320, 480);
        NSValue *cachedFrame = [self.windowDimensions objectForKey:key];
        if (cachedFrame) frame = cachedFrame.CGRectValue;
        
        LDEWindow *window = [[LDEWindow alloc] initWithAttachment:view
                                                        withTitle:actualTitle
                                                   withDimensions:frame];
        [self.targetView addSubview:window.view];
        [windowGroup addObject:window];
    }
}

@end
