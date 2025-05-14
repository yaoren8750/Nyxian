//
//  Main.m
//  LindDE
//
//  Created by fridakitten on 07.05.25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Nyxian-Swift.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    
    ContentViewController *vc = [[ContentViewController alloc] initWithPath:[NSString stringWithFormat:@"%@/Documents/Projects", NSHomeDirectory()]];
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:vc];
    
    SettingsViewController *settingsViewControler = [[SettingsViewController alloc] init];
    UINavigationController *settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewControler];
    
    nvc.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Projects" image:[UIImage systemImageNamed:@"square.grid.2x2.fill"] tag:0];
    settingsNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Settings" image:[UIImage systemImageNamed:@"gear"] tag:1];
    
    tabBarController.viewControllers = @[nvc, settingsNavigationController];
    
    self.window.rootViewController = tabBarController;
    
    [self.window makeKeyAndVisible];

    return YES;
}

@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
