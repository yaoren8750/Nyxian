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

#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <litehook/src/litehook.h>

static OSStatus (*orig_SecItemAdd)(CFDictionaryRef attributes, CFTypeRef *result) = SecItemAdd;
static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef query, CFTypeRef *result) = SecItemCopyMatching;
static OSStatus (*orig_SecItemUpdate)(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) = SecItemUpdate;
static OSStatus (*orig_SecItemDelete)(CFDictionaryRef query) = SecItemDelete;

NSMutableDictionary *SecItemPrepare(CFDictionaryRef query)
{
    NSMutableDictionary *queryCopy = ((__bridge NSDictionary *)query).mutableCopy;
    NSString *accessGroup = queryCopy[(__bridge id)kSecAttrAccessGroup];
    NSString *account = queryCopy[(__bridge id)kSecAttrAccount];

    if (!accessGroup)
        accessGroup = [[NSBundle mainBundle] bundleIdentifier];
    if (account)
    {
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccount];
        queryCopy[(__bridge id)kSecAttrAccount] = [NSString stringWithFormat:@"%@@%@", accessGroup, account];
    } else
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
    
    return queryCopy;
}

OSStatus new_SecItemAdd(CFDictionaryRef query, CFTypeRef *result)
{
    return orig_SecItemAdd((__bridge CFDictionaryRef)SecItemPrepare(query), result);
}

OSStatus new_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result)
{
    return orig_SecItemCopyMatching((__bridge CFDictionaryRef)SecItemPrepare(query), result);
}

OSStatus new_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate)
{
    return orig_SecItemUpdate((__bridge CFDictionaryRef)SecItemPrepare(query), (__bridge CFDictionaryRef)SecItemPrepare(attributesToUpdate));
}

OSStatus new_SecItemDelete(CFDictionaryRef query)
{
    return orig_SecItemDelete((__bridge CFDictionaryRef)SecItemPrepare(query));
}

void SecItemGuestHooksInit(void)
{
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, SecItemAdd, new_SecItemAdd, nil);
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, SecItemCopyMatching, new_SecItemCopyMatching, nil);
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, SecItemUpdate, new_SecItemUpdate, nil);
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, SecItemDelete, new_SecItemDelete, nil);
}
