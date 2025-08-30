//
//  exec.m
//  Nyxian
//
//  Created by SeanIsTethered on 30.08.25.
//

#import "exec.h"
#import "zip.h"

#import <LindChain/LiveContainer/LCUtils.h>
#import <LindChain/LiveContainer/LCAppInfo.h>
#import "../../litehook/src/litehook.h"

static NSObject<TestServiceProtocol> *staticProxy;
DEFINE_HOOK(NSLog, void, (NSString *format, ...))
{
    va_list args;
    va_start(args, format);

    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    // Send message via your proxy
    [staticProxy sendMessage:msg withReply:^(NSString *reply){
        // Optional: handle reply
    }];
}

void NXLog(NSString *format, ...)
{
    va_list args;
    va_start(args, format);

    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    // Send message via your proxy
    [staticProxy sendMessage:msg withReply:^(NSString *reply){
        // Optional: handle reply
    }];
}

NSString* invokeAppMain(NSString *bundlePath, NSString *homePath, int argc, char *argv[]);

NSString *fileTreeAtPathWithArrows(NSString *path) {
    NSMutableString *treeString = [NSMutableString string];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    __block void (^traverse)(NSString *, NSString *, BOOL);
    traverse = ^(NSString *currentPath, NSString *prefix, BOOL isLast) {
        BOOL isDir;
        if (![fm fileExistsAtPath:currentPath isDirectory:&isDir]) {
            return;
        }
        
        NSString *name = [currentPath lastPathComponent];
        NSString *connector = isLast ? @"└── " : @"├── ";
        [treeString appendFormat:@"%@%@%@\n", prefix, connector, name];
        
        if (isDir) {
            NSArray<NSString *> *contents = [fm contentsOfDirectoryAtPath:currentPath error:nil];
            contents = [contents sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
            
            for (NSUInteger i = 0; i < contents.count; i++) {
                NSString *item = contents[i];
                NSString *itemPath = [currentPath stringByAppendingPathComponent:item];
                BOOL last = (i == contents.count - 1);
                NSString *newPrefix = [prefix stringByAppendingString:(isLast ? @"    " : @"│   ")];
                traverse(itemPath, newPrefix, last);
            }
        }
    };
    
    traverse(path, @"", YES);
    return [treeString copy];
}

BOOL clearTemporaryDirectory(NSError **error) {
    NSString *tempDir = NSTemporaryDirectory();
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSArray<NSString *> *contents = [fm contentsOfDirectoryAtPath:tempDir error:error];
    if (!contents) {
        return NO;
    }
    
    BOOL success = YES;
    for (NSString *item in contents) {
        NSString *fullPath = [tempDir stringByAppendingPathComponent:item];
        if (![fm removeItemAtPath:fullPath error:error]) {
            NSLog(@"Failed to remove %@: %@", fullPath, *error);
            success = NO;
        }
    }
    
    return success;
}

void exec(NSObject<TestServiceProtocol> *proxy,
          NSData *ipaPayload,
          NSData *certificateData,
          NSString *certificatePassword)
{
    DO_HOOK_GLOBAL(NSLog);
    
    staticProxy = proxy;
    clearTemporaryDirectory(nil);
    
    // First write out payload
    NSString *payloadPath = [NSString stringWithFormat:@"%@/payload.ipa", NSTemporaryDirectory()];
    NSString *unzippedPath = [NSString stringWithFormat:@"%@Payload", NSTemporaryDirectory()];
    BOOL success = [ipaPayload writeToFile:payloadPath atomically:YES];
    
    if(success)
        NXLog(@"Wrote payload.ipa to tmp");
    else
        NXLog(@"Failed to write payload.ipa to tmp");
    
    NXLog(@"%@: %@",NSTemporaryDirectory(),[[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil]);
    
    // Unzip Payload
    unzipArchiveAtPath(payloadPath, NSTemporaryDirectory());
    NXLog(@"Unzipped payload.ipa to tmp");
    
    // Get BundlePath
    NSString *bundlePath = [NSString stringWithFormat:@"%@/%@",unzippedPath,[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:unzippedPath error:nil] firstObject]];
    
    NXLog(@"%@:\n%@",bundlePath,fileTreeAtPathWithArrows(bundlePath));

    // Sign iOS app
    NSUserDefaults *appGroupUserDefault = [[NSUserDefaults alloc] initWithSuiteName:LCUtils.appGroupID];
    if(!appGroupUserDefault) appGroupUserDefault = [NSUserDefaults standardUserDefaults];
    [appGroupUserDefault setObject:certificateData forKey:@"LCCertificateData"];
    [appGroupUserDefault setObject:certificatePassword forKey:@"LCCertificatePassword"];
    [appGroupUserDefault setObject:[NSDate now] forKey:@"LCCertificateUpdateDate"];
    [[NSUserDefaults standardUserDefaults] setObject:LCUtils.appGroupID forKey:@"LCAppGroupID"];
    
    NXLog(@"Set certificate successfully");
    
    LCAppInfo *appInfo = [[LCAppInfo alloc] initWithBundlePath:bundlePath];
    [proxy sendMessage:@"Created LCAppInfo" withReply:^(NSString *msg){}];
    [appInfo patchExecAndSignIfNeedWithCompletionHandler:^(BOOL result, NSString *meow){
        if(result)
        {
            NXLog(@"Successfully signed iOS application payload");
            [appInfo save];
        }
        else
        {
            NXLog(@"Failed signing iOS application payload");
        }
        CFRunLoopStop(CFRunLoopGetMain());
    } progressHandler:^(NSProgress *prog){
    } forceSign:NO];
    CFRunLoopRun();
    
    NXLog(@"Lets go executing");
    
    char *argv[1] = { NULL };
    int argc = 0;
    
    NSString *error = invokeAppMain(bundlePath, NSHomeDirectory(), argc, argv);
    [proxy sendMessage:error withReply:^(NSString *msg){}];
    
    NXLog(@"Shutting down!");
    
    //NSString *documentDirectory = [NSString stringWithFormat:@"%@/Documents", NSHomeDirectory()];
}
