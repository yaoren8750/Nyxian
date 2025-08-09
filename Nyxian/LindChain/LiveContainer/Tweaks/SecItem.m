//
//  SecItem.m
//  LiveContainer
//
//  Created by s s on 2024/11/29.
//
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import "utils.h"
#import <CommonCrypto/CommonDigest.h>
#import <litehook/src/litehook.h>
#import "LCSharedUtils.h"

extern void* (*msHookFunction)(void *symbol, void *hook, void **old);
OSStatus (*orig_SecItemAdd)(CFDictionaryRef attributes, CFTypeRef *result) = SecItemAdd;
OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef query, CFTypeRef *result) = SecItemCopyMatching;
OSStatus (*orig_SecItemUpdate)(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) = SecItemUpdate;
OSStatus (*orig_SecItemDelete)(CFDictionaryRef query) = SecItemDelete;

OSStatus new_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result)
{
    NSMutableDictionary *attributesCopy = ((__bridge NSDictionary *)attributes).mutableCopy;
    NSString *accessGroup = attributesCopy[(__bridge id)kSecAttrAccessGroup];
    if(!accessGroup)
        accessGroup = [[NSBundle mainBundle] bundleIdentifier];
    NSString *account = attributesCopy[(__bridge id)kSecAttrAccount];
    [attributesCopy removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
    
    attributesCopy[(__bridge id)kSecAttrAccount] = [NSString stringWithFormat:@"%@@%@", accessGroup, account];
    
    OSStatus status = orig_SecItemAdd((__bridge CFDictionaryRef)attributesCopy, result);
    if(status == errSecParam) {
        return orig_SecItemAdd(attributes, result);
    }
    
    return status;
}

OSStatus new_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result)
{
    NSMutableDictionary *queryCopy = ((__bridge NSDictionary *)query).mutableCopy;

    NSString *accessGroup = queryCopy[(__bridge id)kSecAttrAccessGroup];
    NSString *account = queryCopy[(__bridge id)kSecAttrAccount];

    if (!accessGroup) {
        accessGroup = [[NSBundle mainBundle] bundleIdentifier];
    }

    if (account) {
        // Remove original keys to avoid conflicts
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccount];

        // Create combined account string
        queryCopy[(__bridge id)kSecAttrAccount] = [NSString stringWithFormat:@"%@@%@", accessGroup, account];
    }

    // Try original call with modified query
    OSStatus status = orig_SecItemCopyMatching((__bridge CFDictionaryRef)queryCopy, result);
    if (status == errSecParam) {
        // Fallback: try with original query unmodified
        status = orig_SecItemCopyMatching(query, result);
    }

    return status;
}

OSStatus new_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate)
{
    NSMutableDictionary *queryCopy = ((__bridge NSDictionary *)query).mutableCopy;
    NSMutableDictionary *attrCopy = ((__bridge NSDictionary *)attributesToUpdate).mutableCopy;
    
    NSString *accessGroup = queryCopy[(__bridge id)kSecAttrAccessGroup];
    if (!accessGroup) {
        accessGroup = [[NSBundle mainBundle] bundleIdentifier];
    }
    
    NSString *queryAccount = queryCopy[(__bridge id)kSecAttrAccount];
    if (queryAccount) {
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccount];
        queryCopy[(__bridge id)kSecAttrAccount] = [NSString stringWithFormat:@"%@@%@", accessGroup, queryAccount];
    } else {
        // Even if no account in query, remove kSecAttrAccessGroup to avoid conflicts
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
    }

    NSString *attrAccount = attrCopy[(__bridge id)kSecAttrAccount];
    if (attrAccount) {
        [attrCopy removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
        [attrCopy removeObjectForKey:(__bridge id)kSecAttrAccount];
        attrCopy[(__bridge id)kSecAttrAccount] = [NSString stringWithFormat:@"%@@%@", accessGroup, attrAccount];
    } else {
        // Remove access group if present in attributes too
        [attrCopy removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
    }
    
    OSStatus status = orig_SecItemUpdate((__bridge CFDictionaryRef)queryCopy, (__bridge CFDictionaryRef)attrCopy);
    if (status == errSecParam) {
        return orig_SecItemUpdate(query, attributesToUpdate);
    }
    
    return status;
}

OSStatus new_SecItemDelete(CFDictionaryRef query)
{
    NSMutableDictionary *queryCopy = ((__bridge NSDictionary *)query).mutableCopy;

    NSString *accessGroup = queryCopy[(__bridge id)kSecAttrAccessGroup];
    if (!accessGroup) {
        accessGroup = [[NSBundle mainBundle] bundleIdentifier];
    }

    NSString *account = queryCopy[(__bridge id)kSecAttrAccount];
    if (account) {
        // Remove original keys to avoid conflicts
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccount];
        // Combine accessGroup and account like in other functions
        queryCopy[(__bridge id)kSecAttrAccount] = [NSString stringWithFormat:@"%@@%@", accessGroup, account];
    } else {
        // Remove access group if no account to avoid param errors
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
    }

    OSStatus status = orig_SecItemDelete((__bridge CFDictionaryRef)queryCopy);
    if (status == errSecParam) {
        // fallback to original query unmodified
        status = orig_SecItemDelete(query);
    }

    return status;
}

void SecItemGuestHooksInit(void)
{
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, SecItemAdd, new_SecItemAdd, nil);
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, SecItemCopyMatching, new_SecItemCopyMatching, nil);
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, SecItemUpdate, new_SecItemUpdate, nil);
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, SecItemDelete, new_SecItemDelete, nil);
}
