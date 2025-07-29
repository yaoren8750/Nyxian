//
//  Debugger.m
//  Test
//
//  Created by fridakitten on 02.05.25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Private/Restart.h>
#import "Logger.h"
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#import <Nyxian-Swift.h>

UINavigationController *nxloggerview;

///
/// This is a on-device debugger that is in the app you wanna debug
///
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
                [consoleButton.centerYAnchor constraintEqualToAnchor:self.blurView.centerYAnchor constant:-85],
                [consoleButton.widthAnchor constraintEqualToConstant:75],
                [consoleButton.heightAnchor constraintEqualToConstant:75],

                [fileButton.centerXAnchor constraintEqualToAnchor:self.blurView.centerXAnchor],
                [fileButton.centerYAnchor constraintEqualToAnchor:self.blurView.centerYAnchor],
                [fileButton.widthAnchor constraintEqualToConstant:75],
                [fileButton.heightAnchor constraintEqualToConstant:75],

                [backButton.centerXAnchor constraintEqualToAnchor:self.blurView.centerXAnchor],
                [backButton.centerYAnchor constraintEqualToAnchor:self.blurView.centerYAnchor constant:85],
                [backButton.widthAnchor constraintEqualToConstant:75],
                [backButton.heightAnchor constraintEqualToConstant:75],
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
        button.tintColor = UIColor.whiteColor;
    else
        button.tintColor = markColor;

    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];

    return button;
}

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

@end

///
/// Self executed code
///
NyxianDebugger *nxdebugger;

void debugger_main(void)
{
    nxdebugger = [[NyxianDebugger alloc] init];
    nxloggerview = [[UINavigationController alloc] initWithRootViewController:[[LoggerView alloc] init]];
    
    printf("[*] Nyxian Debugger 1.0\n");
}
