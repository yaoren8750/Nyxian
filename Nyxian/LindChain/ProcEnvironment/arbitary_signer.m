/*
 Copyright (C) 2025 cr4zyengineer

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

#import <LindChain/ProcEnvironment/environment.h>
#import <LindChain/ProcEnvironment/proxy.h>
#import <LindChain/LiveContainer/LCAppInfo.h>

extern NSBundle *overridenNSBundleOfNyxian;

NSString* signMachOAtPath(NSString *path)
{
    NSString *resolvedPath = path;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    while (true) {
        NSDictionary *attrs = [fm attributesOfItemAtPath:resolvedPath error:nil];
        NSString *fileType = attrs[NSFileType];
        if ([fileType isEqualToString:NSFileTypeSymbolicLink]) {
            NSString *dest = [fm destinationOfSymbolicLinkAtPath:resolvedPath error:nil];
            if (!dest) {
                return nil;
            }
            if (![dest isAbsolutePath]) {
                dest = [[resolvedPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:dest];
            }
            resolvedPath = [dest stringByStandardizingPath];
            continue;
        }
        break;
    }

    [hostProcessProxy gatherCodeSignerViaReply:^(NSData *certificateData, NSString *certificatePassword){
        NSUserDefaults *appGroupUserDefault = [[NSUserDefaults alloc] initWithSuiteName:LCUtils.appGroupID];
        if(!appGroupUserDefault) appGroupUserDefault = [NSUserDefaults standardUserDefaults];
        [appGroupUserDefault setObject:certificateData forKey:@"LCCertificateData"];
        [appGroupUserDefault setObject:certificatePassword forKey:@"LCCertificatePassword"];
        [appGroupUserDefault setObject:[NSDate now] forKey:@"LCCertificateUpdateDate"];
        [[NSUserDefaults standardUserDefaults] setObject:LCUtils.appGroupID forKey:@"LCAppGroupID"];
        dispatch_semaphore_signal(environment_semaphore);
    }];
    dispatch_semaphore_wait(environment_semaphore, DISPATCH_TIME_FOREVER);
    
    [hostProcessProxy gatherSignerExtrasViaReply:^(NSString *bundle){
        overridenNSBundleOfNyxian = [NSBundle bundleWithPath:bundle];
        dispatch_semaphore_signal(environment_semaphore);
    }];
    dispatch_semaphore_wait(environment_semaphore, DISPATCH_TIME_FOREVER);
    
    NSString *tmpBundle = [NSString stringWithFormat:@"%@/%@.app", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    [fm createDirectoryAtPath:tmpBundle withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString *tmpBinPath = [tmpBundle stringByAppendingPathComponent:@"main"];
    [fm moveItemAtPath:resolvedPath toPath:tmpBinPath error:nil];
    
    NSString *infoPath = [tmpBundle stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *plistDict = @{
        @"CFBundleIdentifier" : overridenNSBundleOfNyxian.bundleIdentifier,
        @"CFBundleExecutable" : @"main",
        @"CFBundleVersion"    : @"1.0.0"
    };
    NSError *error = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:plistDict
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                                  options:0
                                                                    error:&error];
    if (!plistData) {
        return nil;
    }
    if (![plistData writeToFile:infoPath atomically:YES]) {
        return nil;
    }
    
    dispatch_async(dispatch_queue_create("sign-queue", DISPATCH_QUEUE_CONCURRENT), ^{
        LCAppInfo *appInfo = [[LCAppInfo alloc] initWithBundlePath:tmpBundle];
        [appInfo patchExecAndSignIfNeedWithCompletionHandler:^(BOOL succeeded, NSString *errorDescription){
            dispatch_semaphore_signal(environment_semaphore);
        } progressHandler:^(NSProgress *progress) {
        } forceSign:NO];
    });
    dispatch_semaphore_wait(environment_semaphore, DISPATCH_TIME_FOREVER);
    
    [fm removeItemAtPath:path error:nil];
    [fm createSymbolicLinkAtPath:path withDestinationPath:tmpBinPath error:nil];
    
    return path;
}
