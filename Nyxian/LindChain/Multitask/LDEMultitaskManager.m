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

- (void)makeKeyAndVisible
{
    [super makeKeyAndVisible];
    
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        UILongPressGestureRecognizer *gestureRecognizer =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(handleLongPress:)];
        
        gestureRecognizer.numberOfTouchesRequired = 2;
        [self addGestureRecognizer:gestureRecognizer];
    }

}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        if (!self.appSwitcherView)
        {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
            UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            blurView.translatesAutoresizingMaskIntoConstraints = NO;
            blurView.layer.cornerRadius = 20;
            blurView.layer.masksToBounds = YES;

            UIView *container = [[UIView alloc] init];
            container.translatesAutoresizingMaskIntoConstraints = NO;
            container.layer.shadowColor = [UIColor blackColor].CGColor;
            container.layer.shadowOpacity = 0.25;
            container.layer.shadowRadius = 12;
            container.layer.shadowOffset = CGSizeMake(0, -4);

            [container addSubview:blurView];
            [NSLayoutConstraint activateConstraints:@[
                [blurView.topAnchor constraintEqualToAnchor:container.topAnchor],
                [blurView.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
                [blurView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
                [blurView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor]
            ]];

            UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:48 weight:UIImageSymbolWeightRegular];
            UIImage *symbol = [UIImage systemImageNamed:@"app.dashed" withConfiguration:config];
            UIImageView *symbolView = [[UIImageView alloc] initWithImage:symbol];
            symbolView.tintColor = [UIColor secondaryLabelColor];
            symbolView.translatesAutoresizingMaskIntoConstraints = NO;

            UILabel *placeholderLabel = [[UILabel alloc] init];
            placeholderLabel.text = @"No Apps Launched Yet";
            placeholderLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
            placeholderLabel.textColor = [UIColor secondaryLabelColor];
            placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;

            UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[symbolView, placeholderLabel]];
            stack.axis = UILayoutConstraintAxisVertical;
            stack.alignment = UIStackViewAlignmentCenter;
            stack.spacing = 12;
            stack.translatesAutoresizingMaskIntoConstraints = NO;

            [blurView.contentView addSubview:stack];
            [NSLayoutConstraint activateConstraints:@[
                [stack.centerXAnchor constraintEqualToAnchor:blurView.contentView.centerXAnchor],
                [stack.centerYAnchor constraintEqualToAnchor:blurView.contentView.centerYAnchor]
            ]];

            self.appSwitcherView = container;
            [self addSubview:self.appSwitcherView];

            [NSLayoutConstraint activateConstraints:@[
                [self.appSwitcherView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                [self.appSwitcherView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                [self.appSwitcherView.heightAnchor constraintEqualToAnchor:self.heightAnchor multiplier:0.5]
            ]];

            self.appSwitcherTopConstraint =
                [self.appSwitcherView.topAnchor constraintEqualToAnchor:self.bottomAnchor];
            self.appSwitcherTopConstraint.active = YES;
            [self layoutIfNeeded];

            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(handlePan:)];
            [self.appSwitcherView addGestureRecognizer:pan];

            self.impactGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
            [self.impactGenerator prepare];
        }

        [self showAppSwitcher];
    }
}

- (void)showAppSwitcher
{
    self.appSwitcherTopConstraint.active = NO;
    self.appSwitcherTopConstraint = [self.appSwitcherView.topAnchor constraintEqualToAnchor:self.centerYAnchor];
    self.appSwitcherTopConstraint.active = YES;

    [UIView animateWithDuration:0.6
                          delay:0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0.6
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self layoutIfNeeded];
                     } completion:nil];

    [self.impactGenerator impactOccurred];
}

- (void)hideAppSwitcher
{
    self.appSwitcherTopConstraint.active = NO;
    self.appSwitcherTopConstraint = [self.appSwitcherView.topAnchor constraintEqualToAnchor:self.bottomAnchor];
    self.appSwitcherTopConstraint.active = YES;

    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         [self.appSwitcherView removeFromSuperview];
                         self.appSwitcherView = nil;
                         self.appSwitcherTopConstraint = nil;
                     }];

    UIImpactFeedbackGenerator *dismissHaptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [dismissHaptic impactOccurred];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan
{
    CGPoint translation = [pan translationInView:self];

    if (pan.state == UIGestureRecognizerStateChanged)
    {
        CGFloat offset = MAX(0, translation.y);
        self.appSwitcherTopConstraint.constant = offset;
        [self layoutIfNeeded];
    }
    else if (pan.state == UIGestureRecognizerStateEnded ||
             pan.state == UIGestureRecognizerStateCancelled)
    {

        CGFloat velocityY = [pan velocityInView:self].y;
        CGFloat offset = self.appSwitcherTopConstraint.constant;

        if (offset > 100 || velocityY > 500)
        {
            [self hideAppSwitcher];
        } else
        {
            self.appSwitcherTopConstraint.constant = 0;
            [UIView animateWithDuration:0.5
                                  delay:0
                 usingSpringWithDamping:0.8
                  initialSpringVelocity:0.7
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 [self layoutIfNeeded];
                             }
                             completion:nil];
        }
    }
}

@end
