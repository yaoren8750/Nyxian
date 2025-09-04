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

#import "LDEApplicationObject.h"
#import "LDEApplicationWorkspaceInternal.h"

@implementation LDEApplicationObject

- (instancetype)initWithBundle:(NSBundle*)bundle
{
    self = [super init];
    self.bundleIdentifier = bundle.bundleIdentifier;
    self.bundlePath = bundle.bundlePath;
    NSString *displayName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!displayName) {
        displayName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
    }
    if (!displayName) {
        displayName = [bundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
    }
    if (!displayName) {
        displayName = @"Unknown App";
    }
    self.displayName = displayName;
    self.containerPath = [[LDEApplicationWorkspaceInternal shared] applicationContainerForBundleID:bundle.bundleIdentifier];
    
    NSDictionary *iconsDict = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIcons"];
    NSDictionary *primaryIconsDict = [iconsDict objectForKey:@"CFBundlePrimaryIcon"];
    NSArray *iconFiles = [primaryIconsDict objectForKey:@"CFBundleIconFiles"];
    NSString *iconName = [iconFiles lastObject];
    self.icon = [UIImage imageNamed:iconName];
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:self.bundleIdentifier forKey:@"bundleIdentifier"];
    [coder encodeObject:self.bundlePath forKey:@"bundlePath"];
    [coder encodeObject:self.displayName forKey:@"displayName"];
    [coder encodeObject:self.containerPath forKey:@"containerPath"];
    [coder encodeObject:self.icon forKey:@"icon"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    if (self = [super init]) {
        _bundleIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:@"bundleIdentifier"];
        _bundlePath = [coder decodeObjectOfClass:[NSString class] forKey:@"bundlePath"];
        _displayName = [coder decodeObjectOfClass:[NSString class] forKey:@"displayName"];
        _containerPath = [coder decodeObjectOfClass:[NSString class] forKey:@"containerPath"];
        _icon = [coder decodeObjectOfClass:[NSString class] forKey:@"icon"];
    }
    return self;
}

@end
