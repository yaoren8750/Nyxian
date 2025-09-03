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
    NSMutableArray<LDEWindow*> *windowGroup = [self windowGroupForBundleIdentifier:bundleIdentifier];
    if(windowGroup)
    {
        LDEWindow *mainWindow = [windowGroup firstObject];
        if(terminate)
        {
            [windowGroup removeObjectAtIndex:0];
            for(LDEWindow *window in windowGroup)
            {
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
        LDEWindow *decoratedAppSceneViewController = [[LDEWindow alloc] initWithBundleID:bundleIdentifier];
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
    NSMutableArray<LDEWindow*> *windowGroup = [self windowGroupForBundleIdentifier:bundleIdentifier];;
    if(windowGroup) for(LDEWindow *window in windowGroup) [window closeWindow];
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
    for(NSString *key in self.windowGroups) if([key isEqualToString:bundleIdentifier]) return self.windowGroups[key];
    return nil;
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

- (void)attachView:(UIView*)view toWindowGroupOfBundleIdentifier:(NSString*)bundleIdentifier
{
    NSMutableArray<LDEWindow*> *windowGroup = [self windowGroupForBundleIdentifier:bundleIdentifier];
    if(windowGroup)
    {
        LDEWindow *window = [[LDEWindow alloc] initWithAttachment:view withTitle:@"ProofOfConcept"];
        [self.targetView addSubview:window.view];
        [windowGroup addObject:window];
    }
}

@end
