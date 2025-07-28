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
                // FIXME: Fix it in case someone uses a other bundleID
                [[LSApplicationWorkspace defaultWorkspace] openApplicationWithBundleID:@"com.cr4zy.nyxian"];
            }
        });
        
        usleep(1000);
        exit(0);
    });
}
