#import "../FoundationPrivate.h"
#import <Foundation/Foundation.h>
#import "LCSharedUtils.h"
#import "Tweaks.h"
#import <ObjC/Swizzle.h>

extern NSString *lcAppGroupPath;

void NSFMGuestHooksInit(void) {
    [ObjCSwizzler replaceOriginalAction:@selector(containerURLForSecurityApplicationGroupIdentifier:) ofClass:NSFileManager.class withAction:@selector(hook_containerURLForSecurityApplicationGroupIdentifier:)];
}

// NSFileManager simulate app group
@implementation NSFileManager(LiveContainerHooks)

- (nullable NSURL *)hook_containerURLForSecurityApplicationGroupIdentifier:(NSString *)groupIdentifier {
    NSURL *result;
    result = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%s/Documents/AppGroup/%@", getenv("LC_HOME_PATH"), groupIdentifier]];
    [NSFileManager.defaultManager createDirectoryAtURL:result withIntermediateDirectories:YES attributes:nil error:nil];
    return result;
}

@end
