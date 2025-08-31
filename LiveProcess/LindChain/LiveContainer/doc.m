//
//  doc.m
//  Nyxian
//
//  Created by SeanIsTethered on 31.08.25.
//

#import "doc.h"

NSString *homePathForLCAppInfo(LCAppInfo *appInfo)
{
    NSString *bundleIdentifier = [appInfo bundleIdentifier];
    NSString *homePath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), bundleIdentifier];
    return homePath;
}
