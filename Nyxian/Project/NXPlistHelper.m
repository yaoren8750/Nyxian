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

#import <Project/NXPlistHelper.h>

@interface NXPlistHelper ()

@property (nonatomic,strong,readwrite) NSDate *savedModificationDate;

@end

@implementation NXPlistHelper

- (instancetype)initWithPlistPath:(NSString*)plistPath
{
    self = [super init];
    _plistPath = plistPath;
    _savedModificationDate = [self lastFileModificationDate];
    [self reloadData];
    return self;
}

- (NSDate*)lastFileModificationDate
{
    NSError *error = NULL;
    NSDictionary<NSFileAttributeKey, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_plistPath error:&error];
    if(error)
        return [NSDate date];
    NSDate *modDate = [attributes objectForKey:NSURLAttributeModificationDateKey];
    return modDate ? modDate : [NSDate date];
}

- (BOOL)reloadIfNeeded
{
    NSDate *modDate = [self lastFileModificationDate];
    BOOL needsReload = [_savedModificationDate compare:modDate] == NSOrderedAscending;
    if(needsReload)
    {
        _dictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:_plistPath];
        _savedModificationDate = modDate;
    }
    return needsReload;
}

- (void)reloadData
{
    _dictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:_plistPath];
    _savedModificationDate = [self lastFileModificationDate];
}

- (void)writeKey:(NSString*)key
       withValue:(id)value
{
    [_dictionary setObject:value forKey:key];
    [_dictionary writeToFile:_plistPath atomically:YES];
    _savedModificationDate = [self lastFileModificationDate];
}

- (id)readKey:(NSString*)key
{
    return [_dictionary objectForKey:key];
}

- (id)readSecureFromKey:(NSString*)key
       withDefaultValue:(id)value
              classType:Class
{
    id valueOfKey = [_dictionary objectForKey:key];
    if(!valueOfKey && ![valueOfKey isKindOfClass:Class])
        valueOfKey = value;
    return valueOfKey;
}

- (NSString *)readStringForKey:(NSString *)key
              withDefaultValue:(NSString *)defaultValue
{
    return [self readSecureFromKey:key
                  withDefaultValue:defaultValue
                         classType:[NSString class]];
}

- (NSInteger)readIntegerForKey:(NSString *)key
              withDefaultValue:(NSInteger)defaultValue
{
    NSNumber *number = [self readSecureFromKey:key
                              withDefaultValue:@(defaultValue)
                                     classType:[NSNumber class]];
    return [number integerValue];
}

- (BOOL)readBooleanForKey:(NSString *)key
         withDefaultValue:(BOOL)defaultValue
{
    NSNumber *number = [self readSecureFromKey:key
                              withDefaultValue:@(defaultValue)
                                     classType:[NSNumber class]];
    return [number boolValue];
}

- (double)readDoubleForKey:(NSString *)key
          withDefaultValue:(double)defaultValue
{
    NSNumber *number = [self readSecureFromKey:key
                              withDefaultValue:@(defaultValue)
                                     classType:[NSNumber class]];
    return [number doubleValue];
}

- (NSArray*)readArrayForKey:(NSString *)key
           withDefaultValue:(NSArray*)defaultValue
{
    NSArray *array = [self readSecureFromKey:key
                            withDefaultValue:defaultValue
                                   classType:[NSArray class]];
    return array;
}

@end
