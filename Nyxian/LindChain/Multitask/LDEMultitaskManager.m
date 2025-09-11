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
#import <LindChain/Multitask/LDEProcessManager.h>
#if __has_include(<Nyxian-Swift.h>)
#import <Nyxian-Swift.h>
#endif

@implementation LDEMultitaskManager

- (instancetype)init {
    static BOOL hasInitialized = NO;
    if (hasInitialized) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"This class may only be initialized once."
                                     userInfo:nil];
    }
    self = [super initWithFrame:UIScreen.mainScreen.bounds];
    if (self) {
        _windows = [[NSMutableDictionary alloc] init];
        hasInitialized = YES;
    }
    return self;
}

+ (instancetype)shared
{
    static LDEMultitaskManager *multitaskManagerSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        multitaskManagerSingleton = [[LDEMultitaskManager alloc] init];
    });
    return multitaskManagerSingleton;
}

- (BOOL)openWindowForProcessIdentifier:(pid_t)processIdentifier
{
    dispatch_async(dispatch_get_main_queue(), ^{
        LDEProcess *process = [[LDEProcessManager shared] processForProcessIdentifier:processIdentifier];
        if(process)
        {
            LDEWindow *window = [[LDEWindow alloc] initWithProcess:process withDimensions:CGRectMake(50, 50, 300, 400)];
            if(window)
            {
                [self.windows setObject:window forKey:@(processIdentifier)];
                [self addSubview:window.view];
            }
        }
    });
    
    return YES;
}

- (BOOL)closeWindowForProcessIdentifier:(pid_t)processIdentifier
{
    dispatch_async(dispatch_get_main_queue(), ^{
        LDEWindow *window = [self.windows objectForKey:@(processIdentifier)];
        if(window) [window closeWindow];
        [self.windows removeObjectForKey:@(processIdentifier)];
    });
    return YES;
}

@end
