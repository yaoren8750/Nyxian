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

#import "exec.h"
#import "zip.h"
#import "path.h"

#import <LindChain/LiveContainer/LCUtils.h>
#import <LindChain/LiveContainer/LCAppInfo.h>

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

void exec(NSFileHandle *payloadHandle)
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if(!clearTemporaryDirectory(nil))
        exit(1);
    
    // First write out payload
    NSString *unzippedPath = [NSString stringWithFormat:@"%@Payload", NSTemporaryDirectory()];
    if(!unzipArchiveFromFileHandle(payloadHandle, NSTemporaryDirectory()))
        exit(1);
    
    NSLog(@"Unzipped payload.ipa to tmp");
    
    // Get BundlePath
    NSString *bundlePath = [NSString stringWithFormat:@"%@/%@",unzippedPath,[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:unzippedPath error:nil] firstObject]];
    NSLog(@"%@:\n%@",bundlePath,fileTreeAtPathWithArrows(bundlePath));
    
    // Creating LCAppInfo and relocate bundle to a stable path
    LCAppInfo *appInfo = [[LCAppInfo alloc] initWithBundlePath:bundlePath];
    NSLog(@"Lets go executing %@", appInfo.bundlePath);
    
    NSString *homePath = homePathForLCAppInfo(appInfo);
    
    // Relocate application bundle to a stable path
    NSString *newBundlePath = bundlePathForLCAppInfo(appInfo);
    if([fileManager fileExistsAtPath:newBundlePath])
        [fileManager removeItemAtPath:newBundlePath error:nil];
    [fileManager createDirectoryAtURL:[[NSURL fileURLWithPath:newBundlePath] URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager moveItemAtPath:bundlePath toPath:newBundlePath error:nil];
    bundlePath = newBundlePath;
    
    // Executing
    char *argv[1] = { NULL };
    int argc = 0;
    NSString *error = invokeAppMain(bundlePath, homePath, argc, argv);
    NSLog(@"invokeAppMain() failed with error: %@\nGuest app shutting down", error);
}
