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
    
    ContentViewController *vc = [[ContentViewController alloc] initWithPath:[NSString stringWithFormat:@"%@/Documents/Projects", NSHomeDirectory()]];
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:vc];
    self.window.rootViewController = nvc;
    
    [self.window makeKeyAndVisible];

    return YES;
}

@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
