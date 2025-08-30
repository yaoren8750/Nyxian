

#import <UIKit/UIKit.h>
#import <LindChain/ObjC/Swizzle.h>

@implementation UIWindow(LiveProcessHooks)
// Fix blank screen for apps not using SceneDelegate
- (void)hook_makeKeyAndVisible {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(200 * MSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(!self.windowScene) {
            self.windowScene = (id)((UIApplication *)[UIApplication performSelector:@selector(sharedApplication)]).connectedScenes.anyObject;
        }
    });
    [self hook_makeKeyAndVisible];
}
@end

void swizzle(Class class, SEL originalAction, SEL swizzledAction);
__attribute__((constructor)) void LiveProcessHooksInit(void) {
    [ObjCSwizzler replaceInstanceAction:@selector(makeKeyAndVisible) ofClass:UIWindow.class withAction:@selector(hook_makeKeyAndVisible)];
}
