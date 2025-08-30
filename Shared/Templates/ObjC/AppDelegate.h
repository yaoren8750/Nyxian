#import <UIKit/UIKit.h>

#ifndef APPDELEGATE_H
#define APPDELEGATE_H

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>

@property (strong, nonatomic) UIWindow * window;

@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end

#endif /* APPDELEGATE_H */
