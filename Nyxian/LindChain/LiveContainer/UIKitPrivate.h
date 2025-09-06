#import <UIKit/UIKit.h>

@interface UIImage(private)
- (UIImage *)_imageWithSize:(CGSize)size;
@end

@interface UIAlertAction(private)
@property(nonatomic, copy) id shouldDismissHandler;
@end

@interface UIActivityContinuationManager : UIResponder
- (NSDictionary*)handleActivityContinuation:(NSDictionary*)activityDict isSuspended:(id)isSuspended;
@end

@interface UIApplication(private)
- (void)suspend;
- (UIActivityContinuationManager*)_getActivityContinuationManager;
@end

@interface UIContextMenuInteraction(private)
- (void)_presentMenuAtLocation:(CGPoint)location;
@end

@interface _UIContextMenuStyle : NSObject <NSCopying>
@property(nonatomic) NSInteger preferredLayout;
+ (instancetype)defaultStyle;
@end

@interface UIOpenURLAction : NSObject
- (NSURL *)url;
- (instancetype)initWithURL:(NSURL *)arg1;
@end

@interface FBSSceneTransitionContext : NSObject
@property (nonatomic,copy) NSSet * actions;
@end

@interface UIApplicationSceneTransitionContext : FBSSceneTransitionContext
@property (nonatomic,retain) NSDictionary * payload;
@end

@interface UITableViewHeaderFooterView(private)
- (void)setText:(NSString *)text;
- (NSString *)text;
@end

@interface UIApplicationSceneSettings : NSObject
@end

@interface UIApplicationSceneClientSettings : NSObject
@end

@interface UIMutableApplicationSceneSettings : UIApplicationSceneSettings
@property (assign,nonatomic) UIDeviceOrientation deviceOrientation;
- (void)setInterfaceOrientation:(NSInteger)o;
@end



@interface UIMutableApplicationSceneClientSettings : UIApplicationSceneClientSettings
@property (assign,nonatomic) UIDeviceOrientation deviceOrientation;
@property(nonatomic, assign) NSInteger interfaceOrientation;
@property(nonatomic, assign) NSInteger statusBarStyle;
@end


@interface FBSSceneParameters : NSObject
@property(nonatomic, copy) UIApplicationSceneSettings *settings;
@property(nonatomic, copy) UIApplicationSceneClientSettings *clientSettings;
- (instancetype)initWithXPCDictionary:(NSDictionary*)dict;
@end

@interface FBSMutableSceneParameters : FBSSceneParameters
@property(nonatomic, copy) UIMutableApplicationSceneSettings *settings;
@end

@interface UIWindow (private)
- (void)setAutorotates:(BOOL)autorotates forceUpdateInterfaceOrientation:(BOOL)force;
@end

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (BOOL)openApplicationWithBundleID:(NSString *)arg1 ;
@end

@interface UICustomViewMenuElement : UIMenuElement
+ (instancetype)elementWithViewProvider:(UIView *(^)(UICustomViewMenuElement *element))provider;

@end

@interface UINavigationBar(private)
- (UIFont *)_defaultTitleFont;
@end

@interface _UIPrototypingMenuSlider : UISlider
@property(nonatomic, assign, readwrite) CGFloat stepSize;
@end

@interface UISceneActivationRequestOptions(private)
-(void)_setRequestFullscreen:(BOOL)arg1;
@end

@interface _UIButtonBarStackView : UIView
- (void)setSpacing:(CGFloat)spacing;
@end

@interface UIView(private)
- (UIViewController *)_viewControllerForAncestor;
@end


@interface DOCConfiguration : NSObject
- (void)setHostIdentifier:(NSString *)ignored;
@end

#define PrivClass(NAME) NSClassFromString(@#NAME)

@interface LSResourceProxy : NSObject
    @property (setter=_setLocalizedName:,nonatomic,copy) NSString *localizedName;
@end

@interface LSBundleProxy : LSResourceProxy
@end

@interface LSApplicationProxy : LSBundleProxy
    @property(nonatomic, assign, readonly) NSString *bundleIdentifier;
    @property(nonatomic, assign, readonly) NSString *localizedShortName;
    @property(nonatomic, assign, readonly) NSString *primaryIconName;

    @property (nonatomic,readonly) NSString * applicationIdentifier;
    @property (nonatomic,readonly) NSString * applicationType;
    @property (nonatomic,readonly) NSArray * appTags;
    @property (getter=isLaunchProhibited,nonatomic,readonly) BOOL launchProhibited;
    @property (getter=isPlaceholder,nonatomic,readonly) BOOL placeholder;
    @property (getter=isRemovedSystemApp,nonatomic,readonly) BOOL removedSystemApp;
@end

@interface BSCornerRadiusConfiguration : NSObject
- (id)initWithTopLeft:(CGFloat)tl bottomLeft:(CGFloat)bl bottomRight:(CGFloat)br topRight:(CGFloat)tr;
@end

// BoardServices
@interface BSSettings : NSObject
@end

@interface BSTransaction : NSObject
- (void)addChildTransaction:(id)transaction;
- (void)begin;
- (void)setCompletionBlock:(dispatch_block_t)block;
@end

// FrontBoard

@class RBSProcessIdentity, FBProcessExecutableSlice, UIMutableApplicationSceneClientSettings, UIMutableScenePresentationContext, UIScenePresentationManager, _UIScenePresenter;

@interface FBApplicationProcessLaunchTransaction : BSTransaction
- (instancetype) initWithProcessIdentity:(RBSProcessIdentity *)identity executionContextProvider:(id)providerBlock;
- (void)_begin;
@end

@interface FBProcessExecutionContext : NSObject
@end

@interface FBMutableProcessExecutionContext : FBProcessExecutionContext

@property (nonatomic,copy) RBSProcessIdentity * identity;
@property (nonatomic,copy) NSArray * arguments;
@property (nonatomic,copy) NSDictionary * environment;
@property (nonatomic,retain) NSURL * standardOutputURL;
@property (nonatomic,retain) NSURL * standardErrorURL;
@property (assign,nonatomic) BOOL waitForDebugger;
@property (assign,nonatomic) BOOL disableASLR;
@property (assign,nonatomic) BOOL checkForLeaks;
@property (assign,nonatomic) long long launchIntent;
//@property (nonatomic,retain) id<FBProcessWatchdogProviding> watchdogProvider;
@property (nonatomic,copy) NSString * overrideExecutablePath;
//@property (nonatomic,retain) FBProcessExecutableSlice * overrideExecutableSlice;
@property (nonatomic,copy) id completion;
-(id)copyWithZone:(NSZone*)arg1 ;
@end

@interface FBProcess : NSObject
- (id)name;
@end

/*
 Experiment
 */

@protocol BKSTouchEventClient_IPC <NSObject>
@end

@protocol BSDescriptionStreamable <NSObject>

@required

//- (void)appendDescriptionToFormatter:(id <BSDescriptionFormatting>)arg1;

@end

@interface BKSTouchEventService : NSObject <BKSTouchEventClient_IPC>

@property (readonly, copy) NSString *debugDescription; /* unknown property attribute: ? */
@property (readonly, copy) NSString *description;
@property (readonly) unsigned long long hash;
@property (readonly) Class superclass;

+ (id)sharedInstance;

- (void)_connectToService;
- (void)_repostAllRegistrations;
- (void)_updateServerHitTestCategoryContextIDs;
- (id)addAuthenticationSpecifications:(id)arg1 forReason:(id)arg2;
- (void)addTouchAuthenticationSpecifications:(id)arg1 forReason:(id)arg2;
- (id)init;
- (id)registerSceneHostSettings:(id)arg1 forCAContextID:(unsigned int)arg2;
- (id)setContextIDs:(id)arg1 forHitTestContextCategory:(long long)arg2;
- (struct CATransform3D)transformForDisplayUUID:(id)arg1 layerID:(unsigned long long)arg2 contextID:(unsigned int)arg3;

@end

@interface BKSSceneHostSettings : NSObject <BSDescriptionStreamable, NSSecureCoding> {
    NSString * _identifier;
    long long  _touchBehavior;
}

@property (readonly, copy) NSString *debugDescription; /* unknown property attribute: ? */
@property (readonly, copy) NSString *description;
@property (readonly) unsigned long long hash;
@property (nonatomic, readonly) NSString *identifier;
@property (readonly) Class superclass;
@property (nonatomic, readonly) long long touchBehavior;

+ (id)new;
+ (bool)supportsSecureCoding;

- (void)appendDescriptionToFormatter:(id)arg1;
- (id)description;
- (void)encodeWithCoder:(id)arg1;
- (unsigned long long)hash;
- (id)identifier;
- (id)init;
- (id)initWithCoder:(id)arg1;
- (id)initWithIdentifier:(id)arg1 touchBehavior:(long long)arg2;
- (bool)isEqual:(id)arg1;
- (long long)touchBehavior;

@end

@interface FBSceneLayerManager : NSObject

- (id)layers;

@end

@interface FBSceneLayer : NSObject

- (unsigned int)contextID;

@end

@interface BKSSceneHostRegistration : NSObject {
    unsigned int  _contextID;
    BKSSceneHostSettings * _sceneHostSettings;
    BKSTouchEventService * _service;
}

@property (readonly, copy) NSString *debugDescription; /* unknown property attribute: ? */
@property (readonly, copy) NSString *description;
@property (readonly) unsigned long long hash;
@property (readonly) Class superclass;

- (void)appendDescriptionToFormatter:(id)arg1;
- (id)description;
- (void)invalidate;
- (void)updateSettings:(id)arg1;

@end

/*
 Experiment end
 */

@interface FBScene : NSObject

@property (getter=isValid, nonatomic, readonly) bool valid;

- (FBProcess *)clientProcess;
- (UIScenePresentationManager *)uiPresentationManager;
- (void)updateSettings:(UIMutableApplicationSceneSettings *)settings withTransitionContext:(id)context completion:(id)completion;
- (void)updateSettingsWithBlock:(void(^)(UIMutableApplicationSceneSettings *settings))arg1;
- (FBSceneLayerManager*)layerManager;

@end

@interface FBDisplayManager : NSObject
+ (instancetype)sharedInstance;
- (id)mainConfiguration;
@end

@interface FBSSceneClientIdentity : NSObject
+ (instancetype)identityForBundleID:(NSString *)bundleID;
+ (instancetype)identityForProcessIdentity:(RBSProcessIdentity *)identity;
+ (instancetype)localIdentity;
@end

@interface FBProcessManager : NSObject
+ (instancetype)sharedInstance;
- (FBProcessExecutionContext *)launchProcessWithContext:(FBMutableProcessExecutionContext *)context;
- (id)registerProcessForAuditToken:(audit_token_t)token;
- (id)registerProcessForHandle:(id)arg1;
@end

@interface FBSSceneSpecification : NSObject
+ (instancetype)specification;
@end

// RunningBoardServices
@interface RBSProcessIdentity : NSObject
+ (instancetype)identityForEmbeddedApplicationIdentifier:(NSString *)identifier;
+ (instancetype)identityForXPCServiceIdentifier:(NSString *)identifier;
@end

@interface RBSProcessPredicate
+ (instancetype)predicateMatchingIdentifier:(NSNumber *)pid;
@end

@interface RBSProcessHandle
@property(nonatomic, copy, readonly) RBSProcessIdentity *identity;
+ (instancetype)handleForPredicate:(RBSProcessPredicate *)predicate error:(NSError **)error;
- (audit_token_t)auditToken;
- (bool)isValid;
- (int)pid;
@end

@interface RBSTarget : NSObject
@end

@interface UIApplicationSceneSpecification : FBSSceneSpecification
@end

@interface FBSSceneIdentity : NSObject
+ (instancetype)identityForIdentifier:(NSString *)id;
@end

// FBSSceneSettings
@interface UIApplicationSceneSettings(Multitask)
- (bool)isForeground;
- (CGRect)frame;
- (UIInterfaceOrientation)interfaceOrientation;
- (UIMutableApplicationSceneSettings *)mutableCopy;
@end

@interface FBScene (a)
- (UIApplicationSceneSettings*)settings;
@end

@interface UIMutableApplicationSceneSettings(Multitask)
@property(nonatomic, assign, readwrite) BOOL canShowAlerts;
@property(nonatomic, assign) BOOL deviceOrientationEventsEnabled;
@property(nonatomic, assign, readwrite) NSInteger interruptionPolicy;
@property(nonatomic, strong, readwrite) NSString *persistenceIdentifier;
@property (nonatomic, assign, readwrite) UIEdgeInsets peripheryInsets;
@property (nonatomic, assign, readwrite) UIEdgeInsets safeAreaInsetsPortrait, safeAreaInsetsPortraitUpsideDown, safeAreaInsetsLandscapeLeft, safeAreaInsetsLandscapeRight;
@property(assign, nonatomic, readwrite) UIUserInterfaceStyle userInterfaceStyle;
@property(assign, nonatomic, readwrite) UIDeviceOrientation deviceOrientation;
@property (nonatomic, strong, readwrite) BSCornerRadiusConfiguration *cornerRadiusConfiguration;
@property (assign,nonatomic) CGRect statusBarAvoidanceFrame;
@property (assign,nonatomic) double statusBarHeight;
@property (assign,nonatomic, getter=isForeground) bool foreground;
- (id)displayConfiguration;
- (CGRect)frame;
- (NSMutableSet *)ignoreOcclusionReasons;
- (void)setDisplayConfiguration:(id)c;
- (void)setForeground:(BOOL)f;
- (void)setFrame:(CGRect)frame;
- (void)setLevel:(NSInteger)level;
- (void)setStatusBarDisabled:(BOOL)disabled;
- (void)setInterfaceOrientation:(NSInteger)o;
- (BSSettings *)otherSettings;
@end

@interface FBSSceneParameters(Multitask)
+ (instancetype)parametersForSpecification:(FBSSceneSpecification *)spec;
//- (void)updateSettingsWithBlock:(id)block;
@end

@interface FBSMutableSceneDefinition : NSObject
@property(nonatomic, copy) FBSSceneClientIdentity *clientIdentity;
@property(nonatomic, copy) FBSSceneIdentity *identity;
@property(nonatomic, copy) FBSSceneSpecification *specification;
+ (instancetype)definition;
@end

@interface FBSceneManager : NSObject
+ (instancetype)sharedInstance;
- (FBScene *)createSceneWithDefinition:(id)def initialParameters:(id)params;
-(void)destroyScene:(id)arg1 withTransitionContext:(id)arg2 ;
@end

@interface FBSSceneSettingsDiff : NSObject
- (UIMutableApplicationSceneSettings *)settingsByApplyingToMutableCopyOfSettings:(UIApplicationSceneSettings *)settings ;
@end

// UIKit
@protocol _UISceneSettingsDiffAction<NSObject>
@required
- (void)_performActionsForUIScene:(UIScene *)scene withUpdatedFBSScene:(id)fbsScene settingsDiff:(FBSSceneSettingsDiff *)diff fromSettings:(id)settings transitionContext:(id)context lifecycleActionType:(uint32_t)actionType;
@end

@interface UIImage(internal)
+ (instancetype)_applicationIconImageForBundleIdentifier:(NSString *)bundleID format:(NSInteger)format scale:(CGFloat)scale;
@end

@interface UIWindow (Private)
- (instancetype)_initWithFrame:(CGRect)frame attached:(BOOL)attached;
- (void)orderFront:(id)arg1;
@end

@interface _UIRootWindow : UIWindow
@end

@interface UIScreen (Private)
- (CGRect)_referenceBounds;
- (id)displayConfiguration;
@end

@interface UIScenePresentationBinder : NSObject
- (void)addScene:(id)scene;
@end

@interface UIScenePresentationManager : NSObject
- (instancetype)_initWithScene:(FBScene *)scene;
- (_UIScenePresenter *)createPresenterWithIdentifier:(NSString *)identifier;
@end

@interface _UIScenePresenterOwner : NSObject
- (instancetype)initWithScenePresentationManager:(UIScenePresentationManager *)manager context:(FBScene *)scene;
@end

@interface _UIScenePresentationView : UIView
//- (instancetype)initWithPresenter:(_UIScenePresenter *)presenter;
@end

@interface _UIScenePresenter : NSObject
@property (nonatomic, assign, readonly) _UIScenePresentationView *presentationView;
@property(nonatomic, assign, readonly) FBScene *scene;
- (instancetype)initWithOwner:(_UIScenePresenterOwner *)manager identifier:(NSString *)scene sortContext:(NSNumber *)context;
- (void)modifyPresentationContext:(void(^)(UIMutableScenePresentationContext *context))block;
- (void)activate;
- (void)deactivate;
- (void)invalidate;
- (bool)isActive;
- (bool)_isHosting;
@end

@interface UIRootWindowScenePresentationBinder : UIScenePresentationBinder
- (instancetype)initWithPriority:(int)pro displayConfiguration:(id)c;
@end

@interface UIScenePresentationContext : NSObject
- (UIScenePresentationContext *)_initWithDefaultValues;
@end

@interface _UISceneLayerHostContainerView : UIView
- (instancetype)initWithScene:(FBScene *)scene debugDescription:(NSString *)desc;
- (void)_setPresentationContext:(UIScenePresentationContext *)context;
@end

@interface UIScene(Private)
- (void)_registerSettingsDiffActionArray:(NSArray<id<_UISceneSettingsDiffAction>> *)array forKey:(NSString *)key;
- (void)_unregisterSettingsDiffActionArrayForKey:(NSString *)key;
@end

@interface UIApplication()
- (void)launchApplicationWithIdentifier:(NSString *)identifier suspended:(BOOL)suspended;
@end

@interface UIMutableScenePresentationContext : UIScenePresentationContext
@property(nonatomic, assign) NSUInteger appearanceStyle;
@end

@interface UIViewController(Private)
- (void)viewDidMoveToWindow:(UIWindow *)window shouldAppearOrDisappear:(BOOL)appear;
@end

@interface BKSTouchStream : NSObject {
    unsigned int  _reference;
}

@property unsigned int reference;

- (id)initWithContextID:(unsigned int)arg1 displayUUID:(id)arg2 identifier:(unsigned char)arg3 policy:(id)arg4;
- (void)invalidate;
- (unsigned int)reference;
- (void)setEventDispatchMode:(unsigned char)arg1 ambiguityRecommendation:(unsigned char)arg2 lastTouchTimestamp:(double)arg3;
- (void)setEventDispatchMode:(unsigned char)arg1 lastTouchTimestamp:(double)arg2;
- (void)setReference:(unsigned int)arg1;

@end

/*
 HIT TEST
 */
/* Generated by RuntimeBrowser
   Image: /System/Library/PrivateFrameworks/UIKitCore.framework/UIKitCore
 */

@interface _UISystemGestureWindow : _UIRootWindow

+ (bool)_isSecure;

- (bool)_appearsInLoupe;
- (bool)_extendsScreenSceneLifetime;
- (id)_focusResponder;
- (bool)_isSystemGestureWindow;
- (id)_responderForKeyEvents;
- (bool)_shouldPrepareScreenForWindow;
- (id)_systemGestureView;
- (bool)_usesWindowServerHitTesting;
- (bool)canBecomeKeyWindow;
- (id)hitTest:(CGPoint)arg1 withEvent:(id)arg2;
- (id)initWithDisplay:(id)arg1;
- (id)initWithDisplayConfiguration:(id)arg1;
- (id)initWithScreen:(id)arg1;

@end

@interface BKSTouchStreamPolicy : NSObject {
    bool  _shouldSendAmbiguityRecommendations;
}

@property (nonatomic) bool shouldSendAmbiguityRecommendations;

- (void)setShouldSendAmbiguityRecommendations:(bool)arg1;
- (bool)shouldSendAmbiguityRecommendations;

@end
