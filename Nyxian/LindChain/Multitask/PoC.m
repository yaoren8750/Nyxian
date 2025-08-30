//
//  PoC.m
//  Nyxian
//
//  Created by SeanIsTethered on 30.08.25.
//

//#import <LindChain/Private/FoundationPrivate.h>
#import <../LiveProcess/serverDelegate.h>
#import <LindChain/LiveContainer/UIKitPrivate.h>
#import <LindChain/Multitask/AppSceneViewController.h>
#import <LindChain/Multitask/DecoratedAppSceneViewController.h>

pid_t proc_spawn_ios(UIViewController *target)
{
    /*__block pid_t childPid = 0;
    NSBundle *liveProcessBundle = [NSBundle bundleWithPath:[NSBundle.mainBundle.builtInPlugInsPath stringByAppendingPathComponent:@"LiveProcess.appex"]];
    NSError *error = nil;
    NSExtension *ext = [NSExtension extensionWithIdentifier:[liveProcessBundle bundleIdentifier] error:&error];
    if(!error)
    {
        ext.preferredLanguages = @[];
        
        NSExtensionItem *item = [NSExtensionItem new];
        item.userInfo = @{
            @"endpoint": [[ServerManager sharedManager] getEndpointForNewConnections],
        };
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [ext setRequestCancellationBlock:^(NSUUID *uuid, NSError *error) {
            //NSLog(@"Extension wants to stop!");
        }];
        [ext setRequestInterruptionBlock:^(NSUUID *uuid) {
            //NSLog(@"Extension did interrupt");
        }];
        [ext beginExtensionRequestWithInputItems:@[item] completion:^(NSUUID *uuid){
            childPid = [ext pidForRequestIdentifier:uuid];
            //[ext _kill:SIGKILL];
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    sleep(5);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // App Present!
        RBSProcessPredicate* predicate = [PrivClass(RBSProcessPredicate) predicateMatchingIdentifier:@(childPid)];
        
        FBProcessManager *manager = [PrivClass(FBProcessManager) sharedInstance];
        RBSProcessHandle* processHandle = [PrivClass(RBSProcessHandle) handleForPredicate:predicate error:nil];
        [manager registerProcessForAuditToken:processHandle.auditToken];
        NSString *sceneID = [NSString stringWithFormat:@"sceneID:%@-%@", @"LiveProcess", NSUUID.UUID.UUIDString];
        
        FBSMutableSceneDefinition *definition = [PrivClass(FBSMutableSceneDefinition) definition];
        definition.identity = [PrivClass(FBSSceneIdentity) identityForIdentifier:sceneID];
        definition.clientIdentity = [PrivClass(FBSSceneClientIdentity) identityForProcessIdentity:processHandle.identity];
        definition.specification = [UIApplicationSceneSpecification specification];
        FBSMutableSceneParameters *parameters = [PrivClass(FBSMutableSceneParameters) parametersForSpecification:definition.specification];
        
        UIMutableApplicationSceneSettings *settings = [UIMutableApplicationSceneSettings new];
        settings.canShowAlerts = YES;
        settings.cornerRadiusConfiguration = [[PrivClass(BSCornerRadiusConfiguration) alloc] initWithTopLeft:10 bottomLeft:10 bottomRight:10 topRight:10];
        settings.displayConfiguration = UIScreen.mainScreen.displayConfiguration;
        settings.foreground = YES;
        
        settings.deviceOrientation = UIDevice.currentDevice.orientation;
        settings.interfaceOrientation = UIApplication.sharedApplication.statusBarOrientation;
        if(UIInterfaceOrientationIsLandscape(settings.interfaceOrientation)) {
            settings.frame = CGRectMake(0, 0, 500, 200);
        } else {
            settings.frame = CGRectMake(0, 0, 500, 200);
        }
        
        settings.level = 1;
        settings.persistenceIdentifier = NSUUID.UUID.UUIDString;
        settings.peripheryInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        settings.safeAreaInsetsPortrait = UIEdgeInsetsMake(0, 0, 0, 0);
        
        settings.statusBarDisabled = YES;
        //settings.previewMaximumSize =
        //settings.deviceOrientationEventsEnabled = YES;
        parameters.settings = settings;
        
        UIMutableApplicationSceneClientSettings *clientSettings = [UIMutableApplicationSceneClientSettings new];
        clientSettings.interfaceOrientation = UIInterfaceOrientationPortrait;
        clientSettings.statusBarStyle = 0;
        parameters.clientSettings = clientSettings;
        
        FBScene *scene = [[PrivClass(FBSceneManager) sharedInstance] createSceneWithDefinition:definition initialParameters:parameters];
        
        _UIScenePresenter *presenter = [scene.uiPresentationManager createPresenterWithIdentifier:sceneID];
        [presenter modifyPresentationContext:^(UIMutableScenePresentationContext *context) {
            context.appearanceStyle = 2;
        }];
        [presenter activate];
        
        __weak typeof(self) weakSelf = self;
         [ext setRequestInterruptionBlock:^(NSUUID *uuid) {
         [weakSelf appTerminationCleanUp];
         }];
        
        [target.view addSubview:presenter.presentationView];
        target.view.layer.anchorPoint = CGPointMake(0, 0);
        target.view.layer.position = CGPointMake(0, 0);
        
        //[target.view.window.windowScene _registerSettingsDiffActionArray:@[self] forKey:self.sceneID];
    });*/
    
    dispatch_async(dispatch_get_main_queue(), ^{
        DecoratedAppSceneViewController *decoratedAppSceneViewController = [[DecoratedAppSceneViewController alloc] initWindowName:@""];
        [target.view addSubview:decoratedAppSceneViewController.view];
    });
    
    return 0;
}
