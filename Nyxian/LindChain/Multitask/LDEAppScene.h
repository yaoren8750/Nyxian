//
//  AppSceneView.h
//  LiveContainer
//
//  Created by s s on 2025/5/17.
//

#ifndef APPSCENE_H
#define APPSCENE_H

#import <LindChain/LiveContainer/UIKitPrivate.h>
#import <Project/NXProject.h>
#import "FoundationPrivate.h"
#import "../../../LiveProcess/LindChain/LiveProcess/LDEApplicationWorkspace.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class AppSceneViewController;

@protocol AppSceneViewControllerDelegate <NSObject>

- (void)appSceneVCAppDidExit:(AppSceneViewController*)vc;
- (void)appSceneVC:(AppSceneViewController*)vc didInitializeWithError:(NSError*)error;

@optional

- (void)appSceneVC:(AppSceneViewController*)vc didUpdateFromSettings:(UIMutableApplicationSceneSettings *)settings transitionContext:(id)context;

@end

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
            withDebuggingEnabled:(BOOL)enableDebugging
                    withDelegate:(id<AppSceneViewControllerDelegate>)delegate;
- (void)setBackgroundNotificationEnabled:(bool)enabled;
- (void)appTerminationCleanUp:(BOOL)restarts;
- (void)terminate;
- (void)restart;

- (void)resizeActionStart;
- (void)resizeActionEnd;

@end

#endif /* APPSCENE_H */
