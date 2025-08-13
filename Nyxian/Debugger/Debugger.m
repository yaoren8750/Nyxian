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
#import <Private/Restart.h>
#import "Logger.h"
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#import <Nyxian-Swift.h>
#import <litehook/src/litehook.h>
#include <dlfcn.h>
#include <mach/mach.h>
#include <mach/thread_act.h>
#include <mach/thread_state.h>
#import <Decompiler/Decompiler.h>
#include "Utils.h"
#include "MachServer.h"

UINavigationController *nxloggerview;
NyxianDebugger *nxdebugger;

/*
 The Debugger it self
 */
@implementation NyxianDebugger

- (instancetype)init {
    self = [super init];
    if (self) {
        _blurView = NULL;
        _gestureAdded = NO;
        [self waitForRootViewControllerAndAttachGesture];
    }
    return self;
}

- (void)waitForRootViewControllerAndAttachGesture {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf tryAttachGesture];
    });
}

- (void)tryAttachGesture {
    if (_gestureAdded) {
        return;
    }
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootVC = keyWindow.rootViewController;

    if (rootVC) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        longPress.minimumPressDuration = 0.5;
        [rootVC.view addGestureRecognizer:longPress];
        
        _rootViewController = rootVC;
        _gestureAdded = YES;
    } else {
        // Retry after delay
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self tryAttachGesture];
        });
    }
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (_blurView == NULL) {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
            self.blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            self.blurView.frame = _rootViewController.view.bounds;
            self.blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.blurView.alpha = 0.0;
            [_rootViewController.view addSubview:self.blurView];

            UIButton *consoleButton = [self createDebuggerButtonWithSymbol:@"apple.terminal.fill"
                                                                 markColor:nil
                                                                    action:@selector(handleConsoleButton:)];
            UIButton *fileButton = [self createDebuggerButtonWithSymbol:@"folder.fill"
                                                              markColor:nil
                                                                 action:@selector(handleFileButton:)];
            UIButton *backButton = [self createDebuggerButtonWithSymbol:@"arrowshape.turn.up.backward.fill"
                                                              markColor:UIColor.systemRedColor
                                                                 action:@selector(handleBackButton:)];
            
            [_blurView.contentView addSubview:consoleButton];
            [_blurView.contentView addSubview:fileButton];
            [_blurView.contentView addSubview:backButton];

            [NSLayoutConstraint activateConstraints:@[
                [consoleButton.centerXAnchor constraintEqualToAnchor:self.blurView.centerXAnchor],
                [consoleButton.centerYAnchor constraintEqualToAnchor:self.blurView.centerYAnchor constant:-45],

                [fileButton.centerXAnchor constraintEqualToAnchor:self.blurView.centerXAnchor],
                [fileButton.centerYAnchor constraintEqualToAnchor:self.blurView.centerYAnchor constant:45],

                [backButton.centerXAnchor constraintEqualToAnchor:self.blurView.centerXAnchor],
                [backButton.centerYAnchor constraintEqualToAnchor:self.blurView.bottomAnchor constant:-100],
            ]];

            UITapGestureRecognizer *blurTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBlurTap:)];
            blurTap.numberOfTapsRequired = 1;
            [self.blurView addGestureRecognizer:blurTap];

            [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.blurView.alpha = 1.0;
            } completion:nil];
        }
    }
}

- (void)handleBlurTap:(UITapGestureRecognizer *)gesture {
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.blurView.alpha = 0.0;
    } completion:^(BOOL isFinished) {
        if(isFinished)
        {
            [self.blurView removeFromSuperview];
            self.blurView = NULL;
        }
    }];
}

- (UIButton *)createDebuggerButtonWithSymbol:(NSString *)symbolName markColor:(UIColor*)markColor action:(SEL)selector {
    UIButton *button = [[UIButton alloc] init];
    button.backgroundColor = UIColor.systemGray3Color;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.layer.cornerRadius = 15;
    button.layer.borderWidth = 1;
    
    if(!markColor)
        button.layer.borderColor = UIColor.systemGrayColor.CGColor;
    else
        button.layer.borderColor = markColor.CGColor;

    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:30 weight:UIImageSymbolWeightRegular];
    UIImage *symbolImage = [[UIImage systemImageNamed:symbolName] imageByApplyingSymbolConfiguration:config];
    [button setImage:symbolImage forState:UIControlStateNormal];
    
    if(!markColor)
        button.tintColor = UIColor.labelColor;
    else
        button.tintColor = markColor;

    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    
    [NSLayoutConstraint activateConstraints:@[
        [button.widthAnchor constraintEqualToConstant:75],
        [button.heightAnchor constraintEqualToConstant:75],
    ]];

    return button;
}

/*
 Handlers for the Debugger buttons
 */
- (void)handleConsoleButton:(UIButton *)sender
{
    [self.rootViewController presentViewController:nxloggerview animated:YES completion:nil];
}

- (void)handleFileButton:(UIButton *)sender
{
    FileListViewController *fileVC = [[FileListViewController alloc] initWithIsSublink:NO path:NSHomeDirectory()];
    UINavigationController *fileNav = [[UINavigationController alloc] initWithRootViewController:fileVC];
    [self.rootViewController presentViewController:fileNav animated:YES completion:nil];
}

- (void)handleBackButton:(UIButton *)sender
{
    restartProcess();
}

/*
 Crash View
 */
- (void)crashHandle
{
    // TODO: Implement a function that lets the blurview appear in both cases with NULL and without NULL and to safe time in the future for future implementations
    if (_blurView == NULL) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
        self.blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        self.blurView.frame = _rootViewController.view.bounds;
        self.blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.blurView.alpha = 0.0;
        [_rootViewController.view addSubview:self.blurView];
    }
}

@end

/*
 Debugger setup
 */
void debugger_main(void)
{
    /// Escape the death
    /*DO_HOOK_GLOBAL(exit);
    struct sigaction sa;
    sa.sa_sigaction = debugger_signal_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_SIGINFO;

    sigaction(SIGSEGV, &sa, NULL);
    sigaction(SIGABRT, &sa, NULL);
    sigaction(SIGBUS, &sa, NULL);
    sigaction(SIGTRAP, &sa, NULL);*/
    
    machServerInit();
    
    /// Debugger init
    nxdebugger = [[NyxianDebugger alloc] init];
    nxloggerview = [[UINavigationController alloc] initWithRootViewController:[[LoggerView alloc] init]];
}
