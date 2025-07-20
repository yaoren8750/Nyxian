//
//  LindChain.m
//  Nyxian
//
//  Created by SeanIsTethered on 20.07.25.
//

#import <TwinterCore/Modules/LindChain/LindChain.h>

@implementation LindChainModule

- (NSArray<NSString *> *)FindFilesStack:(NSString*)projectPath
                         fileExtensions:(NSArray<NSString *> *)fileExtensions
                                 ignore:(NSArray<NSString *> *)ignore
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Convert arrays to NSSet for efficient lookup
    NSSet<NSString *> *fileExtensionsSet = [NSSet setWithArray:fileExtensions];
    NSSet<NSString *> *ignoreSet = [NSSet setWithArray:ignore];
    
    NSError *error = nil;
    NSArray<NSString *> *allPaths = [fm subpathsOfDirectoryAtPath:projectPath error:&error];
    if (error) {
        return @[];
    }
    
    NSMutableArray<NSString *> *matchedFiles = [NSMutableArray array];
    
    for (NSString *relativePath in allPaths) {
        NSString *fullPath = [projectPath stringByAppendingPathComponent:relativePath];
        
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:fullPath isDirectory:&isDir] && !isDir) {
            
            // Check if file extension matches
            BOOL hasMatchingExtension = NO;
            for (NSString *ext in fileExtensionsSet) {
                if ([relativePath hasSuffix:ext]) {
                    hasMatchingExtension = YES;
                    break;
                }
            }
            if (!hasMatchingExtension) {
                continue;
            }
            
            // Check if relative path starts with any ignored prefix
            BOOL isIgnored = NO;
            for (NSString *ignorePrefix in ignoreSet) {
                if ([relativePath hasPrefix:ignorePrefix]) {
                    isIgnored = YES;
                    break;
                }
            }
            if (isIgnored) {
                continue;
            }
            
            [matchedFiles addObject:fullPath];
        }
    }
    
    return [matchedFiles copy];
}

@end
