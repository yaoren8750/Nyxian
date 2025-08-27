/*
 Copyright (C) 2025 cr4zyengineer
 Copyright (C) 2025 expo

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

#import <Project/NXProject.h>

@implementation NXProjectConfig

- (NSString*)executable { return [self readStringForKey:@"LDEExecutable" withDefaultValue:@"Unknown"]; }
- (NSString*)displayName { return [self readStringForKey:@"LDEDisplayName" withDefaultValue:[self executable]]; }
- (NSString*)bundleid { return [self readStringForKey:@"LDEBundleIdentifier" withDefaultValue:@"com.unknown.fallback.id"]; }
- (NSString*)version { return [self readStringForKey:@"LDEBundleVersion" withDefaultValue:@"1.0"]; }
- (NSString*)shortVersion { return [self readStringForKey:@"LDEBundleShortVersion" withDefaultValue:@"1.0"]; }
- (NSString*)platformTriple { return [self readStringForKey:@"LDEOverwriteTriple" withDefaultValue:[NSString stringWithFormat:@"apple-arm64-ios%@", [self platformMinimumVersion]]]; }
- (NSDictionary*)infoDictionary { return [self readSecureFromKey:@"LDEBundleInfo" withDefaultValue:[[NSDictionary alloc] init] classType:NSDictionary.class]; }
- (NSNumber*)type { return [self readSecureFromKey:@"LDEProjectType" withDefaultValue:[NSNumber numberWithInteger:NXProjectTypeApp] classType:NSNumber.class]; }
- (NSArray*)compilerFlags { return [self readArrayForKey:@"LDECompilerFlags" withDefaultValue:@[]]; }
- (NSArray*)linkerFlags { return [self readArrayForKey:@"LDELinkerFlags" withDefaultValue:@[]]; }
- (NSString*)platformMinimumVersion { return [self readStringForKey:@"LDEMinimumVersion" withDefaultValue:@"1.0"]; }
- (NSNumber*)threads
{
    const int maxThreads = [LDEThreadControl getOptimalThreadCount];
    NSInteger pthreads = [self readIntegerForKey:@"LDEOverwriteThreads" withDefaultValue:[LDEThreadControl getUserSetThreadCount]];
    if(pthreads == 0)
        pthreads = [LDEThreadControl getUserSetThreadCount];
    else if(pthreads > maxThreads)
        pthreads = maxThreads;
    return [NSNumber numberWithInteger:pthreads];
}
- (NSNumber*)increment {
    NSNumber *value = [self readKey:@"LDEOverwriteIncrementalBuild"];
    NSNumber *userSetValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"LDEIncrementalBuild"];
    if(!value)
        return userSetValue ? userSetValue : [NSNumber numberWithBool:YES];
    return value;
}

- (NSMutableArray*)generateCompilerFlags
{
    NSMutableArray *flags = [[NSMutableArray alloc] initWithArray:[self compilerFlags]];
    [flags addObject:@"-target"];
    [flags addObject:[self platformTriple]];
    return flags;
}

@end

@implementation NXCodeEditorConfig

- (NSNumber*)showLine { return [NSNumber numberWithBool:[self readBooleanForKey:@"LDEShowLines" withDefaultValue:YES]]; }
- (NSNumber*)showSpaces { return [NSNumber numberWithBool:[self readBooleanForKey:@"LDEShowSpace" withDefaultValue:YES]]; }
- (NSNumber*)showReturn { return [NSNumber numberWithBool:[self readBooleanForKey:@"LDEShowReturn" withDefaultValue:YES]]; }
- (NSNumber*)wrapLine { return [NSNumber numberWithBool:[self readBooleanForKey:@"LDEWrapLine" withDefaultValue:YES]]; }
- (NSNumber*)fontSize { return [NSNumber numberWithDouble:[self readDoubleForKey:@"LDEFontSize" withDefaultValue:YES]]; }

@end
