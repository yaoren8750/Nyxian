#import "AppDelegate.h"
#import "ViewController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions {
    
    // Ensure the scene is a UIWindowScene
    if (![scene isKindOfClass:[UIWindowScene class]]) return;
    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    
    // Create a UIWindow with the windowScene
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
    // Create the root view controller
    ViewController *rootVC = [[ViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:rootVC];
    
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];
}

- (void)sceneDidDisconnect:(UIScene *)scene {}
- (void)sceneDidBecomeActive:(UIScene *)scene {}
- (void)sceneWillResignActive:(UIScene *)scene {}
- (void)sceneWillEnterForeground:(UIScene *)scene {}
- (void)sceneDidEnterBackground:(UIScene *)scene {}

@end

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Do NOT create a window here if using SceneDelegate
    return YES;
}

@end
