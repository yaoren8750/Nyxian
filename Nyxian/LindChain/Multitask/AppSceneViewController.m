//
//  AppSceneView.m
//  LiveContainer
//
//  Created by s s on 2025/5/17.
//
#import "AppSceneViewController.h"
#import "DecoratedAppSceneViewController.h"
//#import "LiveContainerSwiftUI-Swift.h"
#import <LindChain/LiveContainer/LCUtils.h>
#import "PiPManager.h"
#import "Localization.h"
#import "../../../LiveProcess/serverDelegate.h"

@interface AppSceneViewController()
@property int resizeDebounceToken;
@property CGPoint normalizedOrigin;
@property bool isNativeWindow;
@property NSUUID* identifier;
@end

@interface AppSceneViewController()
@property(nonatomic) UIWindowScene *hostScene;
@property(nonatomic) NSString *sceneID;
@property(nonatomic) NSExtension* extension;
@property(nonatomic) bool isAppTerminationCleanUpCalled;
@property (nonatomic, strong) CADisplayLink *resizeDisplayLink;
@property (nonatomic, strong) NSTimer *resizeEndDebounceTimer;
@end

@implementation AppSceneViewController

- (instancetype)initWithProject:(NXProject*)project withDelegate:(id<AppSceneViewControllerDelegate>)delegate {
    self = [super initWithNibName:nil bundle:nil];
    self.view = [[UIView alloc] init];
    self.contentView = [[UIView alloc] init];
    [self.view addSubview:_contentView];
    self.delegate = delegate;
    self.scaleRatio = 1.0;
    self.isAppTerminationCleanUpCalled = false;
    self.project = project;

    return [self execute] ? self : nil;
}

- (BOOL)execute
{
    // init extension
    NSBundle *liveProcessBundle = [NSBundle bundleWithPath:[NSBundle.mainBundle.builtInPlugInsPath stringByAppendingPathComponent:@"LiveProcess.appex"]];
    if(!liveProcessBundle) {
        [self.delegate appSceneVC:self didInitializeWithError:[NSError errorWithDomain:@"LiveProcess" code:2 userInfo:@{NSLocalizedDescriptionKey: @"LiveProcess extension not found. Please reinstall LiveContainer and select Keep Extensions"}]];
        return NO;
    }
    
    NSError* error = nil;
    _extension = [NSExtension extensionWithIdentifier:liveProcessBundle.bundleIdentifier error:&error];
    if(error) {
        [self.delegate appSceneVC:self didInitializeWithError:error];
        return NO;
    } else {
        [[NSUserDefaults standardUserDefaults] setValue:self.project.packagePath forKey:@"LDEPayloadPath"];
    }
    _extension.preferredLanguages = @[];
    
    NSExtensionItem *item = [NSExtensionItem new];
    item.userInfo = @{
        @"endpoint": [[ServerManager sharedManager] getEndpointForNewConnections],
        @"mode": @"application",
        @"payload": self.project.packagePath,
    };
    
    __weak typeof(self) weakSelf = self;
    [_extension setRequestCancellationBlock:^(NSUUID *uuid, NSError *error) {
        NSLog(@"Extension down!");
        [weakSelf appTerminationCleanUp];
        [weakSelf.delegate appSceneVC:weakSelf didInitializeWithError:error];
    }];
    [_extension setRequestInterruptionBlock:^(NSUUID *uuid) {
        NSLog(@"Extension down!");
        [weakSelf appTerminationCleanUp];
    }];
    [_extension beginExtensionRequestWithInputItems:@[item] completion:^(NSUUID *identifier) {
        if(identifier) {
            //[MultitaskManager registerMultitaskContainerWithContainer:self.dataUUID];
            self.identifier = identifier;
            self.pid = [self.extension pidForRequestIdentifier:self.identifier];
            
            NSLog(@"child process spawned with %u\n", self.pid);
            [self.delegate appSceneVC:self didInitializeWithError:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setUpAppPresenter];
            });
        } else {
            NSError* error = [NSError errorWithDomain:@"LiveProcess" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Failed to start app. Child process has unexpectedly crashed"}];
            NSLog(@"%@", [error localizedDescription]);
            [self.delegate appSceneVC:self didInitializeWithError:error];
        }
    }];
    
    _isNativeWindow = [[[NSUserDefaults alloc] initWithSuiteName:[LCUtils appGroupID]] integerForKey:@"LCMultitaskMode" ] == 1;
    
    return YES;
}

- (void)setUpAppPresenter {
    RBSProcessPredicate* predicate = [PrivClass(RBSProcessPredicate) predicateMatchingIdentifier:@(self.pid)];
    
    FBProcessManager *manager = [PrivClass(FBProcessManager) sharedInstance];
    // At this point, the process is spawned and we're ready to create a scene to render in our app
    RBSProcessHandle* processHandle = [PrivClass(RBSProcessHandle) handleForPredicate:predicate error:nil];
    [manager registerProcessForAuditToken:processHandle.auditToken];
    // NSString *identifier = [NSString stringWithFormat:@"sceneID:%@-%@", bundleID, @"default"];
    self.sceneID = [NSString stringWithFormat:@"sceneID:%@-%@", @"LiveProcess", NSUUID.UUID.UUIDString];
    
    FBSMutableSceneDefinition *definition = [PrivClass(FBSMutableSceneDefinition) definition];
    definition.identity = [PrivClass(FBSSceneIdentity) identityForIdentifier:self.sceneID];
    definition.clientIdentity = [PrivClass(FBSSceneClientIdentity) identityForProcessIdentity:processHandle.identity];
    definition.specification = [UIApplicationSceneSpecification specification];
    FBSMutableSceneParameters *parameters = [PrivClass(FBSMutableSceneParameters) parametersForSpecification:definition.specification];
    
    UIMutableApplicationSceneSettings *settings = [UIMutableApplicationSceneSettings new];
    settings.canShowAlerts = YES;
    settings.cornerRadiusConfiguration = [[PrivClass(BSCornerRadiusConfiguration) alloc] initWithTopLeft:self.view.layer.cornerRadius bottomLeft:self.view.layer.cornerRadius bottomRight:self.view.layer.cornerRadius topRight:self.view.layer.cornerRadius];
    settings.displayConfiguration = UIScreen.mainScreen.displayConfiguration;
    settings.foreground = YES;
    
    settings.deviceOrientation = UIDevice.currentDevice.orientation;
    settings.interfaceOrientation = UIApplication.sharedApplication.statusBarOrientation;
    if(UIInterfaceOrientationIsLandscape(settings.interfaceOrientation)) {
        settings.frame = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width);
    } else {
        settings.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    }
    //settings.interruptionPolicy = 2; // reconnect
    settings.level = 1;
    settings.persistenceIdentifier = NSUUID.UUID.UUIDString;
    if(self.isNativeWindow) {
        UIEdgeInsets defaultInsets = self.view.window.safeAreaInsets;
        settings.peripheryInsets = defaultInsets;
        settings.safeAreaInsetsPortrait = defaultInsets;
    } else {
        // it seems some apps don't honor these settings so we don't cover the top of the app
        settings.peripheryInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        settings.safeAreaInsetsPortrait = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    
    settings.statusBarDisabled = !self.isNativeWindow;
    //settings.previewMaximumSize =
    //settings.deviceOrientationEventsEnabled = YES;
    self.settings = settings;
    parameters.settings = settings;
    
    UIMutableApplicationSceneClientSettings *clientSettings = [UIMutableApplicationSceneClientSettings new];
    clientSettings.interfaceOrientation = UIInterfaceOrientationPortrait;
    clientSettings.statusBarStyle = 0;
    parameters.clientSettings = clientSettings;
    
    FBScene *scene = [[PrivClass(FBSceneManager) sharedInstance] createSceneWithDefinition:definition initialParameters:parameters];
    
    self.presenter = [scene.uiPresentationManager createPresenterWithIdentifier:self.sceneID];
    [self.presenter modifyPresentationContext:^(UIMutableScenePresentationContext *context) {
        context.appearanceStyle = 2;
    }];
    [self.presenter activate];
    
    __weak typeof(self) weakSelf = self;
    [self.extension setRequestInterruptionBlock:^(NSUUID *uuid) {
        [weakSelf appTerminationCleanUp];
    }];
    
    [self.contentView addSubview:self.presenter.presentationView];
    self.contentView.layer.anchorPoint = CGPointMake(0, 0);
    self.contentView.layer.position = CGPointMake(0, 0);
    
    [self.view.window.windowScene _registerSettingsDiffActionArray:@[self] forKey:self.sceneID];
}

- (void)terminate {
    if(self.isAppRunning) {
        NSExtension *targetExtension = self.extension;
        [targetExtension _kill:SIGTERM];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [targetExtension _kill:SIGKILL];
        });
    }
}

- (void)restart {
    [_extension setRequestCancellationBlock:^(NSUUID *uuid, NSError *error) {}];
    [_extension setRequestInterruptionBlock:^(NSUUID *uuid) {}];
    [self terminate];
    [self appTerminationCleanUp];
    _isAppTerminationCleanUpCalled = NO;
    [self execute];
}

- (void)_performActionsForUIScene:(UIScene *)scene withUpdatedFBSScene:(id)fbsScene settingsDiff:(FBSSceneSettingsDiff *)diff fromSettings:(UIApplicationSceneSettings *)settings transitionContext:(id)context lifecycleActionType:(uint32_t)actionType {
    if(!self.isAppRunning) {
        [self appTerminationCleanUp];
    }
    if(!diff) return;
    
    UIMutableApplicationSceneSettings *baseSettings = [diff settingsByApplyingToMutableCopyOfSettings:settings];
    UIApplicationSceneTransitionContext *newContext = [context copy];
    newContext.actions = nil;
    if(self.isNativeWindow) {
        // directly update the settings
        baseSettings.interruptionPolicy = 0;
        baseSettings.peripheryInsets = self.view.window.safeAreaInsets;
        [self.presenter.scene updateSettings:baseSettings withTransitionContext:newContext completion:nil];
    } else {
        [self.delegate appSceneVC:self didUpdateFromSettings:baseSettings transitionContext:newContext];
    }
}

- (void)viewWillLayoutSubviews {
    [self startLiveResizeWithSettingsBlock:self.nextUpdateSettingsBlock];
    self.nextUpdateSettingsBlock = nil;
}

- (BOOL)isAppRunning {
    return _pid > 0 && getpgid(_pid) > 0;
}

- (void)appTerminationCleanUp {
    if (_isAppTerminationCleanUpCalled) return;
    _isAppTerminationCleanUpCalled = YES;

    void (^cleanupBlock)(void) = ^{
        if (self.sceneID) {
            [[PrivClass(FBSceneManager) sharedInstance] destroyScene:self.sceneID withTransitionContext:nil];
        }
        if (self.presenter) {
            [self.presenter deactivate];
            [self.presenter invalidate];
            self.presenter = nil;
        }

        [self.delegate appSceneVCAppDidExit:self];
    };

    if ([NSThread isMainThread]) {
        cleanupBlock();
    } else {
        dispatch_sync(dispatch_get_main_queue(), cleanupBlock);
    }
}

- (void)setBackgroundNotificationEnabled:(bool)enabled {
    if(enabled) {
        // Re-add UIApplicationDidEnterBackgroundNotification
        [NSNotificationCenter.defaultCenter addObserver:self.extension selector:@selector(_hostDidEnterBackgroundNote:) name:UIApplicationDidEnterBackgroundNotification object:UIApplication.sharedApplication];
    } else {
        // Remove UIApplicationDidEnterBackgroundNotification so apps like YouTube can continue playing video
        [NSNotificationCenter.defaultCenter removeObserver:self.extension name:UIApplicationDidEnterBackgroundNotification object:UIApplication.sharedApplication];
    }
}

- (void)viewDidMoveToWindow:(UIWindow *)newWindow shouldAppearOrDisappear:(BOOL)appear {
    [super viewDidMoveToWindow:newWindow shouldAppearOrDisappear:appear];
    if(!newWindow) {
        if(self.sceneID) {
            [self.view.window.windowScene _unregisterSettingsDiffActionArrayForKey:self.sceneID];
        }
        self.delegate = nil;
    }
}

- (void)startLiveResizeWithSettingsBlock:(void (^)(UIMutableApplicationSceneSettings *settings))block {
    self.pendingSettingsBlock = block;
    
    if (!self.resizeDisplayLink) {
        self.resizeDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateSceneFrame)];
        [self.resizeDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        self.resizeDisplayLink.paused = YES;
    }
}

- (void)updateSceneFrame {
    if (!self.presenter || !self.presenter.scene) return;

    CGRect frame = CGRectMake(
        self.view.frame.origin.x,
        self.view.frame.origin.y,
        self.view.frame.size.width / self.scaleRatio,
        self.view.frame.size.height / self.scaleRatio
    );

    [self.presenter.scene updateSettingsWithBlock:^(UIMutableApplicationSceneSettings *settings) {
        settings.deviceOrientation = UIDevice.currentDevice.orientation;
        settings.interfaceOrientation = self.view.window.windowScene.interfaceOrientation;

        if (UIInterfaceOrientationIsLandscape(settings.interfaceOrientation)) {
            settings.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.height, frame.size.width);
        } else {
            settings.frame = frame;
        }
        if (self.pendingSettingsBlock) {
            self.pendingSettingsBlock(settings);
        }
    }];
}

- (void)endLiveResize {
    [self.resizeDisplayLink invalidate];
    self.resizeDisplayLink = nil;
    self.pendingSettingsBlock = nil;
}

- (void)resizeActionStart {
    [self.resizeEndDebounceTimer invalidate];
    self.resizeEndDebounceTimer = nil;
    self.resizeDisplayLink.paused = NO;
}

- (void)resizeActionEnd {
    [self.resizeEndDebounceTimer invalidate];
    __weak typeof(self) weakSelf = self;
    self.resizeEndDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:NO block:^(NSTimer * _Nonnull timer) {
        weakSelf.resizeDisplayLink.paused = YES;
        weakSelf.resizeEndDebounceTimer = nil;
    }];
}

@end
 
