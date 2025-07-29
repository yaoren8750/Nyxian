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

LoggerView *nxloggerview;

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
        if(_blurView == NULL)
        {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
            self.blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            self.blurView.frame = _rootViewController.view.bounds;
            self.blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.blurView.alpha = 0.0;
            
            UIButton *consoleButton = [[UIButton alloc] init];
            consoleButton.backgroundColor = UIColor.systemGray3Color;
            consoleButton.translatesAutoresizingMaskIntoConstraints = NO;
            consoleButton.layer.cornerRadius = 15;
            consoleButton.layer.borderWidth = 1;
            consoleButton.layer.borderColor = UIColor.systemGrayColor.CGColor;
            [consoleButton addTarget:self
                              action:@selector(handleConsoleButton:)
                    forControlEvents:UIControlEventTouchUpInside];
            
            UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:30 weight:UIImageSymbolWeightRegular];
            UIImage *symbolImage = [[UIImage systemImageNamed:@"apple.terminal.fill"] imageByApplyingSymbolConfiguration:config];
            [consoleButton setImage:symbolImage forState:UIControlStateNormal];
            consoleButton.tintColor = UIColor.whiteColor;
            
            [_blurView.contentView addSubview:consoleButton];
            [_rootViewController.view addSubview:self.blurView];
            
            [NSLayoutConstraint activateConstraints:@[
                [consoleButton.centerXAnchor constraintEqualToAnchor:self.blurView.centerXAnchor],
                [consoleButton.centerYAnchor constraintEqualToAnchor:self.blurView.centerYAnchor constant:-45],
                [consoleButton.widthAnchor constraintEqualToConstant:75],
                [consoleButton.heightAnchor constraintEqualToConstant:75]
            ]];
            
            UIButton *backButton = [[UIButton alloc] init];
            backButton.backgroundColor = UIColor.systemGray3Color;
            backButton.translatesAutoresizingMaskIntoConstraints = NO;
            backButton.layer.cornerRadius = 15;
            backButton.layer.borderWidth = 1;
            backButton.layer.borderColor = UIColor.systemGrayColor.CGColor;
            [backButton addTarget:self
                              action:@selector(handleBackButton:)
                    forControlEvents:UIControlEventTouchUpInside];
            
            UIImage *backSymbolImage = [[UIImage systemImageNamed:@"arrowshape.turn.up.backward.fill"] imageByApplyingSymbolConfiguration:config];
            [backButton setImage:backSymbolImage forState:UIControlStateNormal];
            backButton.tintColor = UIColor.whiteColor;
            
            [_blurView.contentView addSubview:backButton];
            [_rootViewController.view addSubview:self.blurView];
            
            [NSLayoutConstraint activateConstraints:@[
                [backButton.centerXAnchor constraintEqualToAnchor:self.blurView.centerXAnchor],
                [backButton.centerYAnchor constraintEqualToAnchor:self.blurView.centerYAnchor constant:45],
                [backButton.widthAnchor constraintEqualToConstant:75],
                [backButton.heightAnchor constraintEqualToConstant:75]
            ]];
            
            UITapGestureRecognizer *longPress = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBlurTap:)];
            longPress.numberOfTapsRequired = 1;
            [self.blurView addGestureRecognizer:longPress];
            
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

- (void)handleConsoleButton:(UIButton *)sender
{
    [self.rootViewController presentViewController:nxloggerview animated:YES completion:nil];
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
    nxloggerview = [[LoggerView alloc] init];
    nxloggerview.modalPresentationStyle = UIModalPresentationPageSheet;
    
    printf("[*] Nyxian Debugger 1.0\n");
}
