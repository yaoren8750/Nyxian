//
//  Dyld.m
//  LiveContainer
//
//  Created by s s on 2025/2/7.
//

#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <stdlib.h>
#include <sys/mman.h>
#import "litehook_internal.h"
#import "LCMachOUtils.h"
#import "../utils.h"
#import <LindChain/ProcEnvironment/environment.h>

NSString* signMachOAtPath(NSString *path);
extern NSBundle *lcMainBundle;

typedef struct {
    uint32_t platform;
    uint32_t version;
} dyld_build_version_t;

uint32_t lcImageIndex = 0;
uint32_t appMainImageIndex = 0;
uint32_t guestAppSdkVersion = 0;
uint32_t guestAppSdkVersionSet = 0;

void* appExecutableHandle = 0;
const char* lcMainBundlePath = NULL;
void overwriteAppExecutableFileType(void);

static inline int translateImageIndex(int origin)
{
    if(origin == lcImageIndex)
    {
        overwriteAppExecutableFileType();
        return appMainImageIndex;
    }
    return origin;
}

DEFINE_HOOK(_dyld_image_count, uint32_t, (void))
{
    return ORIG_FUNC(_dyld_image_count)() - 1;
}

DEFINE_HOOK(_dyld_get_image_header, const struct mach_header*, (uint32_t image_index))
{
    __attribute__((musttail)) return ORIG_FUNC(_dyld_get_image_header)(translateImageIndex(image_index));
}

DEFINE_HOOK(dlsym, void*, (void * __handle, const char * __symbol))
{
    if(__handle == (void*)RTLD_MAIN_ONLY)
    {
        if(strcmp(__symbol, MH_EXECUTE_SYM) == 0)
        {
            overwriteAppExecutableFileType();
            return (void*)ORIG_FUNC(_dyld_get_image_header)(appMainImageIndex);
        }
        __handle = appExecutableHandle;
    } else if (__handle != (void*)RTLD_SELF && __handle != (void*)RTLD_NEXT)
    {
        void* ans = ORIG_FUNC(dlsym)(__handle, __symbol);
        if(!ans)
            return 0;
        for(int i = 0; i < gRebindCount; i++)
        {
            global_rebind rebind = gRebinds[i];
            if(ans == rebind.replacee)
                return rebind.replacement;
        }
        return ans;
    }
    
    __attribute__((musttail)) return ORIG_FUNC(dlsym)(__handle, __symbol);
}

DEFINE_HOOK(_dyld_get_image_vmaddr_slide, intptr_t, (uint32_t image_index))
{
    __attribute__((musttail)) return ORIG_FUNC(_dyld_get_image_vmaddr_slide)(translateImageIndex(image_index));
}

DEFINE_HOOK(_dyld_get_image_name, const char*, (uint32_t image_index))
{
    __attribute__((musttail)) return ORIG_FUNC(_dyld_get_image_name)(translateImageIndex(image_index));
}

DEFINE_HOOK(dlopen, void *, (const char * __path, int __mode))
{
    // Check CS
    if(!checkCodeSignature(__path))
    {
        // Sign if invalid
        environment_proxy_sign_macho([NSString stringWithCString:__path encoding:NSUTF8StringEncoding]);
    }
    
    // Continue with opening
    return ORIG_FUNC(dlopen)(__path, __mode);
}

bool hook_dyld_program_sdk_at_least(void* dyldApiInstancePtr, dyld_build_version_t version)
{
    // we are targeting ios, so we hard code 2
    switch(version.platform)
    {
        case 0xffffffff:
            return version.version <= guestAppSdkVersionSet;
        case 2:
            return version.version <= guestAppSdkVersion;
        default:
            return false;
    }
}

uint32_t hook_dyld_get_program_sdk_version(void* dyldApiInstancePtr)
{
    return guestAppSdkVersion;
}

// Rewrite End

bool performHookDyldApi(const char* functionName, uint32_t adrpOffset, void** origFunction, void* hookFunction)
{
    uint32_t* baseAddr = dlsym(RTLD_DEFAULT, functionName);
    assert(baseAddr != 0);
    uint32_t* adrpInstPtr = baseAddr + adrpOffset;
    assert ((*adrpInstPtr & 0x9f000000) == 0x90000000);
    uint32_t immlo = (*adrpInstPtr & 0x60000000) >> 29;
    uint32_t immhi = (*adrpInstPtr & 0xFFFFE0) >> 5;
    int64_t imm = (((int64_t)((immhi << 2) | immlo)) << 43) >> 31;
    void* gdyldPtr = (void*)(((uint64_t)baseAddr & 0xfffffffffffff000) + imm);
    uint32_t* ldrInstPtr1 = baseAddr + adrpOffset + 1;
    assert((*ldrInstPtr1 & 0xBFC00000) == 0xB9400000);
    uint32_t size = (*ldrInstPtr1 & 0xC0000000) >> 30;
    uint32_t imm12 = (*ldrInstPtr1 & 0x3FFC00) >> 10;
    gdyldPtr += (imm12 << size);
    assert(gdyldPtr != 0);
    assert(*(void**)gdyldPtr != 0);
    void* vtablePtr = **(void***)gdyldPtr;
    void* vtableFunctionPtr = 0;
    uint32_t* movInstPtr = baseAddr + adrpOffset + 6;
    if((*movInstPtr & 0x7F800000) == 0x52800000)
    {
        uint32_t imm16 = (*movInstPtr & 0x1FFFE0) >> 5;
        vtableFunctionPtr = vtablePtr + imm16;
    } else if ((*movInstPtr & 0xFFE00C00) == 0xF8400C00)
    {
        uint32_t imm9 = (*movInstPtr & 0x1FF000) >> 12;
        vtableFunctionPtr = vtablePtr + imm9;
    } else
    {
        uint32_t* ldrInstPtr2 = baseAddr + adrpOffset + 3;
        assert((*ldrInstPtr2 & 0xBFC00000) == 0xB9400000);
        uint32_t size2 = (*ldrInstPtr2 & 0xC0000000) >> 30;
        uint32_t imm12_2 = (*ldrInstPtr2 & 0x3FFC00) >> 10;
        vtableFunctionPtr = vtablePtr + (imm12_2 << size2);
    }
    kern_return_t ret = builtin_vm_protect(mach_task_self(), (mach_vm_address_t)vtableFunctionPtr, sizeof(uintptr_t), false, PROT_READ | PROT_WRITE | VM_PROT_COPY);
    assert(ret == KERN_SUCCESS);
    if(origFunction != NULL)
        *origFunction = (void*)*(void**)vtableFunctionPtr;
    *(uint64_t*)vtableFunctionPtr = (uint64_t)hookFunction;
    builtin_vm_protect(mach_task_self(), (mach_vm_address_t)vtableFunctionPtr, sizeof(uintptr_t), false, PROT_READ);
    return true;
}

// Rewritten
void overwriteAppExecutableFileType(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct mach_header_64 *header = (struct mach_header_64*) orig__dyld_get_image_header(appMainImageIndex);
        kern_return_t kr = builtin_vm_protect(mach_task_self(), (vm_address_t)header, sizeof(header), false, PROT_READ | PROT_WRITE | VM_PROT_COPY);
        if(kr != KERN_SUCCESS)
            return;
        header->filetype = MH_EXECUTE;
        builtin_vm_protect(mach_task_self(), appMainImageIndex, sizeof(struct mach_header), false, PROT_READ);
    });
}
// Rewritten END

bool initGuestSDKVersionInfo(void)
{
    void* dyldBase = getDyldBase();
    // it seems Apple is constantly changing findVersionSetEquivalent's signature so we directly search sVersionMap instead
    const char* dyldPath = "/usr/lib/dyld";
    uint64_t offset = LCFindSymbolOffset(dyldPath, "__ZN5dyld3L11sVersionMapE");
    uint32_t *versionMapPtr = dyldBase + offset;
    
    assert(versionMapPtr);
    // however sVersionMap's struct size is also unknown, but we can figure it out
    // we assume the size is 10K so we won't need to change this line until maybe iOS 40
    uint32_t* versionMapEnd = versionMapPtr + 2560;
    // ensure the first is versionSet and the third is iOS version (5.0.0)
    assert(versionMapPtr[0] == 0x07db0901 && versionMapPtr[2] == 0x00050000);
    // get struct size. we assume size is smaller then 128. appearently Apple won't have so many platforms
    uint32_t size = 0;
    for(int i = 1; i < 128; ++i)
    {
        // find the next versionSet (for 6.0.0)
        if(versionMapPtr[i] == 0x07dc0901) {
            size = i;
            break;
        }
    }
    assert(size);
    
    NSOperatingSystemVersion currentVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    uint32_t maxVersion = ((uint32_t)currentVersion.majorVersion << 16) | ((uint32_t)currentVersion.minorVersion << 8);
    
    uint32_t candidateVersion = 0;
    uint32_t candidateVersionEquivalent = 0;
    uint32_t newVersionSetVersion = 0;
    for(uint32_t* nowVersionMapItem = versionMapPtr; nowVersionMapItem < versionMapEnd; nowVersionMapItem += size)
    {
        newVersionSetVersion = nowVersionMapItem[2];
        if (newVersionSetVersion > guestAppSdkVersion) { break; }
        candidateVersion = newVersionSetVersion;
        candidateVersionEquivalent = nowVersionMapItem[0];
        if(newVersionSetVersion >= maxVersion) { break; }
    }
    
    if(newVersionSetVersion == 0xffffffff && candidateVersion == 0)
    {
        candidateVersionEquivalent = newVersionSetVersion;
    }

    guestAppSdkVersionSet = candidateVersionEquivalent;
    
    return true;
}

void DyldHooksInit(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        int imageCount = _dyld_image_count();
        for(int i = 0; i < imageCount; ++i)
        {
            const struct mach_header* currentImageHeader = _dyld_get_image_header(i);
            if(currentImageHeader->filetype == MH_EXECUTE)
            {
                lcImageIndex = i;
                break;
            }
        }
        lcMainBundlePath = lcMainBundle.bundlePath.fileSystemRepresentation;
        
        DO_HOOK_GLOBAL(dlsym)
        DO_HOOK_GLOBAL(_dyld_image_count)
        DO_HOOK_GLOBAL(_dyld_get_image_header)
        DO_HOOK_GLOBAL(_dyld_get_image_vmaddr_slide)
        DO_HOOK_GLOBAL(_dyld_get_image_name)
        DO_HOOK_GLOBAL(dlopen);
        
        // Hack remove iOS 26 UI support (for now)
        guestAppSdkVersion = 1179648; // Is 18.0
        if(!initGuestSDKVersionInfo() ||
           !performHookDyldApi("dyld_program_sdk_at_least", 1, NULL, hook_dyld_program_sdk_at_least) ||
           !performHookDyldApi("dyld_get_program_sdk_version", 0, NULL, hook_dyld_get_program_sdk_version))
        {
            return;
        }
    });
}

void* getGuestAppHeader(void)
{
    return (void*)orig__dyld_get_image_header(appMainImageIndex);
}

#pragma mark - Fix black screen
static void *lockPtrToIgnore;
void hook_libdyld_os_unfair_recursive_lock_lock_with_options(void *ptr, void* lock, uint32_t options)
{
    if(!lockPtrToIgnore)
        lockPtrToIgnore = lock;
    if(lock != lockPtrToIgnore)
        os_unfair_recursive_lock_lock_with_options(lock, options);
}
void hook_libdyld_os_unfair_recursive_lock_unlock(void *ptr, void* lock)
{
    if(lock != lockPtrToIgnore)
        os_unfair_recursive_lock_unlock(lock);
}

void *dlopenBypassingLock(const char *path, int mode)
{
    const char *libdyldPath = "/usr/lib/system/libdyld.dylib";
    mach_header_u *libdyldHeader = LCGetLoadedImageHeader(0, libdyldPath);
    assert(libdyldHeader != NULL);
    void **lockUnlockPtr = NULL;
    void **vtableLibSystemHelpers = litehook_find_dsc_symbol(libdyldPath, "__ZTVN5dyld416LibSystemHelpersE");
    void *lockFunc = litehook_find_dsc_symbol(libdyldPath, "__ZNK5dyld416LibSystemHelpers42os_unfair_recursive_lock_lock_with_optionsEP26os_unfair_recursive_lock_s24os_unfair_lock_options_t");
    void *unlockFunc = litehook_find_dsc_symbol(libdyldPath, "__ZNK5dyld416LibSystemHelpers31os_unfair_recursive_lock_unlockEP26os_unfair_recursive_lock_s");
    while(!lockUnlockPtr)
    {
        if(vtableLibSystemHelpers[0] == lockFunc)
        {
            lockUnlockPtr = vtableLibSystemHelpers;
            NSCAssert(vtableLibSystemHelpers[1] == unlockFunc, @"dyld has changed: lock and unlock functions are not next to each other");
            break;
        }
        vtableLibSystemHelpers++;
    }
    kern_return_t ret;
    ret = builtin_vm_protect(mach_task_self(), (mach_vm_address_t)lockUnlockPtr, sizeof(uintptr_t[2]), false, PROT_READ | PROT_WRITE | VM_PROT_COPY);
    assert(ret == KERN_SUCCESS);
    void *origLockPtr = lockUnlockPtr[0], *origUnlockPtr = lockUnlockPtr[1];
    lockUnlockPtr[0] = hook_libdyld_os_unfair_recursive_lock_lock_with_options;
    lockUnlockPtr[1] = hook_libdyld_os_unfair_recursive_lock_unlock;
    void *result = dlopen(path, mode);
    ret = builtin_vm_protect(mach_task_self(), (mach_vm_address_t)lockUnlockPtr, sizeof(uintptr_t[2]), false, PROT_READ | PROT_WRITE);
    assert(ret == KERN_SUCCESS);
    lockUnlockPtr[0] = origLockPtr;
    lockUnlockPtr[1] = origUnlockPtr;
    ret = builtin_vm_protect(mach_task_self(), (mach_vm_address_t)lockUnlockPtr, sizeof(uintptr_t[2]), false, PROT_READ);
    assert(ret == KERN_SUCCESS);
    return result;
}
