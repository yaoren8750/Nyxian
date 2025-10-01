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

#import <LindChain/LaunchServices/LaunchService.h>
#import <LindChain/ProcEnvironment/Server/Server.h>
#import <LindChain/ProcEnvironment/Object/FDMapObject.h>

@implementation LaunchService

- (instancetype)initWithPlistPath:(NSString *)plistPath
{
    self = [super init];
    _dictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSNumber *num = [_dictionary valueForKey:@"LSShouldAutorestart"];
    _autorestart = (num == nil) ? NO : num.boolValue;
    
    [self ignition];
    
    return self;
}

- (void)ignition
{
    // Spawn process
    NSNumber *userIdentifierObject = [_dictionary objectForKey:@"LSUserIdentifier"];
    NSNumber *groupIdentifierObject = [_dictionary objectForKey:@"LSGroupIdentifier"];
    
    uid_t userIdentifier = (userIdentifierObject == nil) ? 501 : userIdentifierObject.unsignedIntValue;
    gid_t groupIdentifier = (groupIdentifierObject == nil) ? 501 : groupIdentifierObject.unsignedIntValue;
    
    NSMutableDictionary *mutableDictionary = [_dictionary mutableCopy];
    [mutableDictionary setObject:[Server getTicket] forKey:@"LSEndpoint"];
    [mutableDictionary setObject:[FDMapObject currentMap] forKey:@"LSFDMapObject"];
    
    pid_t pid = [[LDEProcessManager shared] spawnProcessWithItems:[mutableDictionary copy] withConfiguration:[[LDEProcessConfiguration alloc] initWithParentProcessIdentifier:getpid() withUserIdentifier:userIdentifier withGroupIdentifier:groupIdentifier withEntitlements:PEEntitlementDefaultSystemApplication]];
    if(pid == 0) [self ignition];
    
    // Get process
    _process = [[LDEProcessManager shared] processForProcessIdentifier:pid];
    if(_process == nil) [self ignition];
    
    // Now assign handlers
    if(_autorestart)
    {
        __weak typeof(self) weakSelf = self;
        [_process setExitingCallback:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf ignition];
            });
        }];
    }
}

@end

@implementation LaunchServices

- (instancetype)init
{
    self = [super init];
    _launchServices = [[NSMutableArray alloc] init];
    
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *plistPath = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Shared"] stringByAppendingPathComponent:@"LaunchServices"];
    NSArray<NSString*> *plists = [fm contentsOfDirectoryAtPath:plistPath error:nil];
   
    for(NSString *plist in plists)
    {
        [_launchServices addObject:[[LaunchService alloc] initWithPlistPath:[plistPath stringByAppendingPathComponent:plist]]];
    }
    
    return self;
}

+ (instancetype)shared
{
    static LaunchServices *launchServicesSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        launchServicesSingleton = [[LaunchServices alloc] init];
    });
    return launchServicesSingleton;
}

@end
