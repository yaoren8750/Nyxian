//
//  AppSceneView.h
//  LiveContainer
//
//  Created by s s on 2025/5/17.
//
#import <LindChain/LiveContainer/UIKitPrivate.h>
#import <Project/NXProject.h>
#import "FoundationPrivate.h"
#import "../../../LiveProcess/LindChain/LiveProcess/LDEApplicationWorkspace.h"
@import UIKit;
@import Foundation;


@class AppSceneViewController;

API_AVAILABLE(ios(16.0))
@protocol AppSceneViewControllerDelegate <NSObject>
- (void)appSceneVCAppDidExit:(AppSceneViewController*)vc;
- (void)appSceneVC:(AppSceneViewController*)vc didInitializeWithError:(NSError*)error;
@optional
- (void)appSceneVC:(AppSceneViewController*)vc didUpdateFromSettings:(UIMutableApplicationSceneSettings *)settings transitionContext:(id)context;
@end

API_AVAILABLE(ios(16.0))
@interface AppSceneViewController : UIViewController<_UISceneSettingsDiffAction>

@property(nonatomic) LDEApplicationObject *appObj;
@property(nonatomic) void(^nextUpdateSettingsBlock)(UIMutableApplicationSceneSettings *settings);
@property(nonatomic) int pid;
@property(nonatomic) id<AppSceneViewControllerDelegate> delegate;
@property(nonatomic) BOOL isAppRunning;
@property(nonatomic) CGFloat scaleRatio;
@property(nonatomic) UIView* contentView;
@property(nonatomic) _UIScenePresenter *presenter;
@property (nonatomic, copy) void (^pendingSettingsBlock)(UIMutableApplicationSceneSettings *settings);
@property(nonatomic) UIMutableApplicationSceneSettings *settings;

- (instancetype)initWithBundleID:(NSString*)bundleID
                    withDelegate:(id<AppSceneViewControllerDelegate>)delegate;
- (void)setBackgroundNotificationEnabled:(bool)enabled;
- (void)appTerminationCleanUp;
- (void)terminate;
- (void)restart;

- (void)resizeActionStart;
- (void)resizeActionEnd;

@end
