//
//  exec.m
//  Nyxian
//
//  Created by SeanIsTethered on 30.08.25.
//

#import "exec.h"
#import "zip.h"

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
    clearTemporaryDirectory(nil);
    
    // First write out payload
    NSString *payloadPath = [NSString stringWithFormat:@"%@/payload.ipa", NSTemporaryDirectory()];
    NSString *unzippedPath = [NSString stringWithFormat:@"%@Payload", NSTemporaryDirectory()];
    BOOL success = [ipaPayload writeToFile:payloadPath atomically:YES];
    
    if(success)
        [proxy sendMessage:@"Wrote payload.ipa to tmp" withReply:^(NSString *msg){}];
    else
        [proxy sendMessage:@"Failed to write payload.ipa to tmp" withReply:^(NSString *msg){}];
    
    [proxy sendMessage:[NSString stringWithFormat:@"%@: %@",NSTemporaryDirectory(),[[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil]] withReply:^(NSString *msg){}];
    
    // Unzip Payload
    unzipArchiveAtPath(payloadPath, NSTemporaryDirectory());
    [proxy sendMessage:@"Unzipped payload.ipa to tmp" withReply:^(NSString *msg){}];
    
    // Get BundlePath
    NSString *bundlePath = [NSString stringWithFormat:@"%@/%@",unzippedPath,[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:unzippedPath error:nil] firstObject]];
    
    [proxy sendMessage:[NSString stringWithFormat:@"%@:\n%@",bundlePath,fileTreeAtPathWithArrows(bundlePath)] withReply:^(NSString *msg){}];
    
    // Sign iOS app
    
    //NSString *documentDirectory = [NSString stringWithFormat:@"%@/Documents", NSHomeDirectory()];
}
