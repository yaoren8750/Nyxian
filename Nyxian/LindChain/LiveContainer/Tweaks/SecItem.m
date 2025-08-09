//
//  SecItem.m
//  LiveContainer
//
//  Created by s s on 2024/11/29.
//
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <litehook/src/litehook.h>

static OSStatus (*orig_SecItemAdd)(CFDictionaryRef attributes, CFTypeRef *result) = SecItemAdd;
static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef query, CFTypeRef *result) = SecItemCopyMatching;
static OSStatus (*orig_SecItemUpdate)(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) = SecItemUpdate;
static OSStatus (*orig_SecItemDelete)(CFDictionaryRef query) = SecItemDelete;

OSStatus new_SecItemAdd(CFDictionaryRef query, CFTypeRef *result)
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
    
    OSStatus status = orig_SecItemAdd((__bridge CFDictionaryRef)queryCopy, result);
    
    return status;
}

OSStatus new_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result)
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

    return orig_SecItemCopyMatching((__bridge CFDictionaryRef)queryCopy, result);
}

OSStatus new_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate)
{
    NSMutableDictionary *queryCopy = ((__bridge NSDictionary *)query).mutableCopy;
    NSMutableDictionary *attrCopy = ((__bridge NSDictionary *)attributesToUpdate).mutableCopy;
    NSString *accessGroup = queryCopy[(__bridge id)kSecAttrAccessGroup];
    NSString *queryAccount = queryCopy[(__bridge id)kSecAttrAccount];
    
    if (!accessGroup)
        accessGroup = [[NSBundle mainBundle] bundleIdentifier];
    if (queryAccount)
    {
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccount];
        queryCopy[(__bridge id)kSecAttrAccount] = [NSString stringWithFormat:@"%@@%@", accessGroup, queryAccount];
    } else
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccessGroup];

    NSString *attrAccount = attrCopy[(__bridge id)kSecAttrAccount];
    if (attrAccount) {
        [attrCopy removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
        [attrCopy removeObjectForKey:(__bridge id)kSecAttrAccount];
        attrCopy[(__bridge id)kSecAttrAccount] = [NSString stringWithFormat:@"%@@%@", accessGroup, attrAccount];
    } else
        [attrCopy removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
    
    return orig_SecItemUpdate((__bridge CFDictionaryRef)queryCopy, (__bridge CFDictionaryRef)attrCopy);
}

OSStatus new_SecItemDelete(CFDictionaryRef query)
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
    
    return orig_SecItemDelete((__bridge CFDictionaryRef)queryCopy);
}

void SecItemGuestHooksInit(void)
{
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, SecItemAdd, new_SecItemAdd, nil);
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, SecItemCopyMatching, new_SecItemCopyMatching, nil);
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, SecItemUpdate, new_SecItemUpdate, nil);
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, SecItemDelete, new_SecItemDelete, nil);
}
