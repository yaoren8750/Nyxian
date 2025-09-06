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

- (instancetype)initWithBundle:(MIBundle*)bundle
{
    self = [super init];
    
    self.bundleIdentifier = bundle.identifier;
    self.bundlePath = [[bundle bundleURL] path];
    self.displayName = bundle.displayName;
    self.containerPath = [[LDEApplicationWorkspaceInternal shared] applicationContainerForBundleID:bundle.identifier];
    
    NSString *infoPlistPath = [[[bundle bundleURL] path] stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
    NSDictionary *iconsDict = infoDict[@"CFBundleIcons"];
    NSDictionary *primaryIconDict = iconsDict[@"CFBundlePrimaryIcon"];
    NSArray *iconFiles = primaryIconDict[@"CFBundleIconFiles"];
    NSString *iconName = [iconFiles lastObject];
    NSString *iconPath = [[[bundle bundleURL] path] stringByAppendingPathComponent:iconName];
    if (![iconPath.pathExtension length]) iconPath = [iconPath stringByAppendingPathExtension:@"png"];
    UIImage *iconImage = [UIImage imageWithContentsOfFile:iconPath];
    self.icon = iconImage;
    
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
