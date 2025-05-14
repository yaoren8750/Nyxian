//
//  Restart.m
//  LindDE
//
//  Created by fridakitten on 10.05.25.
//

#import <Foundation/Foundation.h>
#import <Private/LSApplicationWorkspace.h>

void restartProcess(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while(YES)
            {
                [[LSApplicationWorkspace defaultWorkspace] openApplicationWithBundleID:[[NSBundle mainBundle] bundleIdentifier]];
            }
        });
        
        usleep(500);
        exit(0);
    });
}
