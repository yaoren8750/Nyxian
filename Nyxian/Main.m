//
//  Main.m
//  Nyxian
//
//  Created by SeanIsTethered on 28.07.25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Nyxian-Swift.h>
#import "bridge.h"

/*
 Entry point
 */
int main(int argc, char * argv[]) {
    @autoreleasepool {
        NSString *appPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"LDEAppPath"];
        if(appPath) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LDEAppPath"];
            debugger_main();
            invokeAppMain(appPath, [[NSUserDefaults standardUserDefaults] stringForKey:@"LDEHomePath"], 0, nil);
        } else {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
        }
    }
}
