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
#import <CommonCrypto/CommonDigest.h>

extern NSBundle *overridenNSBundleOfNyxian;

NSString *hashOfFileAtPath(NSString *path) {
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!fileHandle) {
        return nil;
    }
    
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    
    while (true) {
        @autoreleasepool {
            NSData *data = [fileHandle readDataOfLength:4096];
            if (data.length == 0) break;
            CC_SHA256_Update(&ctx, data.bytes, (CC_LONG)data.length);
        }
    }
    [fileHandle closeFile];
    
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &ctx);
    
    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hex appendFormat:@"%02x", digest[i]];
    }
    return hex;
}

NSString* signMachOAtPath(NSString *path)
{
    NSString *hash = hashOfFileAtPath(path);
    if(!hash) return nil;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *cacheDir = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"ArbSign"];
    [fm createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString *bundlePath = [cacheDir stringByAppendingPathComponent:[hash stringByAppendingPathExtension:@"app"]];
    NSString *binPath = [bundlePath stringByAppendingPathComponent:@"main"];
    NSString *infoPath = [bundlePath stringByAppendingPathComponent:@"Info.plist"];
    
    if([fm fileExistsAtPath:bundlePath]) return binPath;
    
    // Gather signing info
    NSData *certificateData = nil;
    NSString *certificatePassword = nil;
    NSString *extras = nil;
    environment_proxy_gather_code_signature_info(&certificateData, &certificatePassword);
    extras = environment_proxy_gather_code_signature_extras();
    if(!(certificateData && certificatePassword && extras)) return nil;
    
    NSUserDefaults *appGroupUserDefault = [[NSUserDefaults alloc] initWithSuiteName:LCUtils.appGroupID];
    if(!appGroupUserDefault) appGroupUserDefault = [NSUserDefaults standardUserDefaults];
    [appGroupUserDefault setObject:certificateData forKey:@"LCCertificateData"];
    [appGroupUserDefault setObject:certificatePassword forKey:@"LCCertificatePassword"];
    [appGroupUserDefault setObject:[NSDate now] forKey:@"LCCertificateUpdateDate"];
    [[NSUserDefaults standardUserDefaults] setObject:LCUtils.appGroupID forKey:@"LCAppGroupID"];
    
    // Override signer bundle
    overridenNSBundleOfNyxian = [NSBundle bundleWithPath:extras];
    
    // Create bundle structure
    [fm createDirectoryAtPath:bundlePath withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Copy binary into bundle
    if (![fm copyItemAtPath:path toPath:binPath error:nil]) {
        return nil;
    }
    
    // Write Info.plist with hash marker
    NSDictionary *plistDict = @{
        @"CFBundleIdentifier" : overridenNSBundleOfNyxian.bundleIdentifier ?: @"com.nyxian.unsigned",
        @"CFBundleExecutable" : @"main",
        @"CFBundleVersion"    : @"1.0.0",
        @"NyxianOriginalHash" : hash
    };
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:plistDict
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                                  options:0
                                                                    error:nil];
    [plistData writeToFile:infoPath atomically:YES];
    
    // Run signer
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_async(dispatch_queue_create("sign-queue", DISPATCH_QUEUE_CONCURRENT), ^{
    LCAppInfo *appInfo = [[LCAppInfo alloc] initWithBundlePath:bundlePath];
        [appInfo patchExecAndSignIfNeedWithCompletionHandler:^(BOOL succeeded, NSString *errorDescription){
            dispatch_semaphore_signal(sema);
        } progressHandler:^(NSProgress *progress) {
        } forceSign:NO];
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return binPath;
}
