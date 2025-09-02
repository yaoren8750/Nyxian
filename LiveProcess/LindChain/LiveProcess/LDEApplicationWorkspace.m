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

#import "LDEApplicationWorkspace.h"

@interface LDEApplicationWorkspace ()

@property (nonatomic,strong) NSString *applicationsPath;
@property (nonatomic,strong) NSString *containersPath;

@end

@implementation LDEApplicationWorkspace

/*
 Init
 */
- (instancetype)init
{
    self = [super init];
    
    // Setting up paths
    self.applicationsPath = [NSString stringWithFormat:@"%@/Documents/Applications", NSHomeDirectory()];
    self.containersPath = [NSString stringWithFormat:@"%@/Documents/Containers", NSHomeDirectory()];
    
    // Creating paths if they dont exist
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:self.applicationsPath])
        [fileManager createDirectoryAtPath:self.applicationsPath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    
    if(![fileManager fileExistsAtPath:self.containersPath])
        [fileManager createDirectoryAtPath:self.containersPath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    
    return self;
}

+ (LDEApplicationWorkspace*)shared
{
    static LDEApplicationWorkspace *applicationWorkspaceSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        applicationWorkspaceSingleton = [[LDEApplicationWorkspace alloc] init];
    });
    return applicationWorkspaceSingleton;
}

/*
 Helper
 */
- (NSArray<NSBundle*>*)applicationBundleList
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *uuidPaths = [fileManager contentsOfDirectoryAtPath:self.applicationsPath error:nil];
    NSMutableArray<NSBundle*> *applicationBundleList = [[NSMutableArray alloc] init];
    for(NSString *uuidPath in uuidPaths)
    {
        NSString *bundlePath = [NSString stringWithFormat:@"%@/%@", self.applicationsPath, uuidPath];
        [applicationBundleList addObject:[NSBundle bundleWithPath:bundlePath]];
    }
    return applicationBundleList;
}

/*
 Action
 */
NSString *fileTreeAtPathWithArrows(NSString *path);
- (BOOL)installApplicationAtBundlePath:(NSString*)bundlePath
{
    // Getting bundle at bundlePath
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    if(!bundle) return NO;
    
    // Is bundleID installed? If yes remove previous bundle
    NSBundle *previousApplication = nil;
    if([self applicationInstalledWithBundleID:bundle.bundleIdentifier])
    {
        previousApplication = [self applicationBundleForBundleID:bundle.bundleIdentifier];
        [[NSFileManager defaultManager] removeItemAtPath:previousApplication.bundlePath error:nil];
    }
    
    // Now generating new path or using old path
    NSString *installPath = nil;
    if(previousApplication) {
        // It existed before, using old path
        installPath = previousApplication.bundlePath;
        previousApplication = nil;
    } else {
        // It didnt existed before, using new path
        installPath = [NSString stringWithFormat:@"%@/%@", self.applicationsPath,[[NSUUID UUID] UUIDString]];
    }
    
    // Now installing at install location
    [[NSFileManager defaultManager] moveItemAtPath:bundle.bundlePath toPath:installPath error:nil];
    
    return YES;
}

- (BOOL)deleteApplicationWithBundleID:(NSString *)bundleID
{
    NSBundle *previousApplication = [self applicationBundleForBundleID:bundleID];
    if(previousApplication)
    {
        [[NSFileManager defaultManager] removeItemAtPath:previousApplication.bundlePath error:nil];
        return YES;
    }
    return NO;
}

- (BOOL)applicationInstalledWithBundleID:(NSString*)bundleID
{
    NSArray<NSBundle*> *bundleList = [self applicationBundleList];
    for(NSBundle *bundle in bundleList) if([bundle.bundleIdentifier isEqualToString:bundleID]) return YES;
    return NO;
}

- (NSBundle*)applicationBundleForBundleID:(NSString *)bundleID
{
    NSArray<NSBundle*> *bundleList = [self applicationBundleList];
    for(NSBundle *bundle in bundleList) if([bundle.bundleIdentifier isEqualToString:bundleID]) return bundle;
    return NULL;
}

- (NSString*)applicationContainerForBundleID:(NSString *)bundleID
{
    NSBundle *bundle = [self applicationBundleForBundleID:bundleID];
    NSString *uuid = [bundle.bundleURL lastPathComponent];
    return [NSString stringWithFormat:@"%@/%@", self.containersPath, uuid];
}

@end
