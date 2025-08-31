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

#import <LindChain/Multitask/MultitaskManager.h>

///
/// Class to make it easier,cleaner and more reliable to multitask
///
@implementation LDEMultitaskManager

- (instancetype)init
{
    _windows = [[NSMutableArray alloc] init];
    return [super init];
}

///
/// Shared singleton to make all happen on the same thing
///
+ (LDEMultitaskManager*)shared
{
    static LDEMultitaskManager *multitaskManagerSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        multitaskManagerSingleton = [[LDEMultitaskManager alloc] init];
    });
    return multitaskManagerSingleton;
}

///
/// Open the target application in a window with the project referencing the application
///
/// `project` is the project referencing the application
///
- (BOOL)openApplicationWithProject:(NXProject *)project
{
    __block BOOL result = NO;
    void (^workBlock)(void) = ^{
        static UIWindow *targetWindow = nil;
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
                            targetWindow = w;
                            break;
                        }
                    }
                }
            }
        });
        if (!targetWindow)
        {
            result = NO;
            return;
        }
        [[NSUserDefaults standardUserDefaults] setValue:project.packagePath forKey:@"LDEPayloadPath"];
        DecoratedAppSceneViewController *decoratedAppSceneViewController = [[DecoratedAppSceneViewController alloc] initWithProject:project];
        [targetWindow addSubview:decoratedAppSceneViewController.view];
        [self.windows addObject:decoratedAppSceneViewController];
        result = YES;
    };

    if ([NSThread isMainThread])
        workBlock();
    else
        dispatch_sync(dispatch_get_main_queue(), workBlock);

    return result;
}

///
/// Open the target application in a window with the path to the project referencing the application
///
/// `projectPath` is the project path referencing the applications project
///
- (BOOL)openApplicationWithProjectPath:(NSString *)projectPath
{
    return [self openApplicationWithProject:[[NXProject alloc] initWithPath:projectPath]];
}

@end
