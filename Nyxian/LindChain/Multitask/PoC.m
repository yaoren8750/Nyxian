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

pid_t proc_spawn_ios(NSString *windowTitle)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        DecoratedAppSceneViewController *decoratedAppSceneViewController = [[DecoratedAppSceneViewController alloc] initWindowName:windowTitle];
        [[[UIApplication sharedApplication] keyWindow] addSubview:decoratedAppSceneViewController.view];
    });
    
    return 0;
}
