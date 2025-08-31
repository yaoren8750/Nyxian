//
//  doc.m
//  Nyxian
//
//  Created by SeanIsTethered on 31.08.25.
//

#import "path.h"

NSString *homePathForLCAppInfo(LCAppInfo *appInfo)
{
    NSString *bundleIdentifier = [appInfo bundleIdentifier];
    NSString *homePath = [NSString stringWithFormat:@"%@/Documents/Document/%@", NSHomeDirectory(), bundleIdentifier];
    return homePath;
}

NSString *bundlePathForLCAppInfo(LCAppInfo *appInfo)
{
    NSString *bundleIdentifier = [appInfo bundleIdentifier];
    NSString *bundlePath = [NSString stringWithFormat:@"%@/Documents/Bundle/%@", NSHomeDirectory(), bundleIdentifier];
    return bundlePath;
}
