//
//  BinaryExecutor.m
//  Nyxian
//
//  Created by SeanIsTethered on 28.07.25.
//

#import <LiveContainer/LCUtils.h>
#import <LiveContainer/LCAppInfo.h>

/*
 MARK: This is a important function
 
 This function makes everything easier.
 It executes a binary like exec()
 
 Just that it uses LC JITless stuff to dynamically execute binaries and code
 */

// TODO: Finish it
void lcexec(NSString *binaryPath) {
    // First generate tmp path
    NSString *tmpBundle = [NSString stringWithFormat:@"%@/%@.app", NSTemporaryDirectory(), [[NSUUID UUID] UUIDString]];
    
    // Create that path
    [[NSFileManager defaultManager] createDirectoryAtPath:tmpBundle
                              withIntermediateDirectories:true
                                               attributes:NULL
                                                    error:NULL];
    
}
