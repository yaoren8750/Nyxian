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

#import <UIKit/UIKit.h>

@implementation LDEApplicationObject

- (instancetype)initWithBundle:(MIBundle*)bundle
{
    self = [super init];
    
    self.bundleIdentifier = bundle.identifier;
    self.bundlePath = [[bundle bundleURL] path];
    self.displayName = bundle.displayName;
    self.containerPath = [[[LDEApplicationWorkspaceInternal shared] applicationContainerForBundleID:bundle.identifier] path];
    
    if (self.bundlePath.length == 0) return nil;

    NSBundle *nsBundle = [NSBundle bundleWithPath:self.bundlePath];
    if (!nsBundle) return self;

    NSDictionary *info = nsBundle.infoDictionary ?: @{};
    NSArray<NSDictionary *> *iconContainers = @[
        info[@"CFBundleIcons~iphone"] ?: @{},
        info[@"CFBundleIcons~ipad"]   ?: @{},
        info[@"CFBundleIcons"]        ?: @{}
    ];

    UIUserInterfaceIdiom idiom = UIDevice.currentDevice.userInterfaceIdiom;
    CGFloat scale = UIScreen.mainScreen.scale;
    UITraitCollection *traits = [UITraitCollection traitCollectionWithTraitsFromCollections:@[
        [UITraitCollection traitCollectionWithUserInterfaceIdiom:idiom],
        [UITraitCollection traitCollectionWithDisplayScale:scale]
    ]];

    for (NSDictionary *iconsDict in iconContainers)
    {
        NSDictionary *primary = iconsDict[@"CFBundlePrimaryIcon"];
        NSString *assetName = primary[@"CFBundleIconName"];
        if (assetName.length)
        {
            self.icon = [UIImage imageNamed:assetName inBundle:nsBundle compatibleWithTraitCollection:traits];
            if(self.icon) return self;
        }
    }

    for (NSDictionary *iconsDict in iconContainers)
    {
        NSDictionary *primary = iconsDict[@"CFBundlePrimaryIcon"];
        NSArray *files = primary[@"CFBundleIconFiles"];
        for (NSString *base in [files reverseObjectEnumerator])
        {
            if(base.length == 0) continue;

            self.icon = [UIImage imageNamed:base inBundle:nsBundle compatibleWithTraitCollection:traits];
            if(self.icon) return self;

            NSArray<NSString *> *exts = @[ @"png", @"jpg" ];
            for (NSString *ext in exts)
            {
                NSString *path = [nsBundle pathForResource:base ofType:ext];
                if (path.length)
                {
                    self.icon = [UIImage imageWithContentsOfFile:path];
                    if(self.icon) return self;
                }
            }
        }
    }

    NSArray<NSString *> *allPaths = [nsBundle pathsForResourcesOfType:@"png" inDirectory:nil];
    UIImage *best = nil;
    CGFloat bestArea = 0;
    for (NSString *path in allPaths)
    {
        NSString *name = path.lastPathComponent.lowercaseString;
        if ([name containsString:@"appicon"] || [name containsString:@"icon"])
        {
            UIImage *img = [UIImage imageWithContentsOfFile:path];
            CGSize sz = img.size;
            CGFloat area = sz.width * sz.height * img.scale * img.scale;
            if (img && area > bestArea)
            {
                best = img;
                bestArea = area;
            }
        }
    }
    
    self.icon = best;

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
    if(self = [super init])
    {
        _bundleIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:@"bundleIdentifier"];
        _bundlePath = [coder decodeObjectOfClass:[NSString class] forKey:@"bundlePath"];
        _displayName = [coder decodeObjectOfClass:[NSString class] forKey:@"displayName"];
        _containerPath = [coder decodeObjectOfClass:[NSString class] forKey:@"containerPath"];
        _icon = [coder decodeObjectOfClass:[UIImage class] forKey:@"icon"];
    }
    return self;
}

@end
