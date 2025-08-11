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

extern NSBundle *lcMainBundle;

typedef struct {
    uint32_t platform;
    uint32_t version;
} dyld_build_version_t;

uint32_t (*orig_dyld_image_count)(void) = _dyld_image_count;
uint32_t (*orig_dyld_get_program_sdk_version)(void* dyldPtr);
uint32_t lcImageIndex = 0;
uint32_t appMainImageIndex = 0;
uint32_t guestAppSdkVersion = 0;
uint32_t guestAppSdkVersionSet = 0;

bool (*orig_dyld_program_sdk_at_least)(void* dyldPtr, dyld_build_version_t version);
bool tweakLoaderLoaded = false;

void* (*orig_dlsym)(void * __handle, const char * __symbol) = dlsym;
void* appExecutableHandle = 0;

const char* (*orig_dyld_get_image_name)(uint32_t image_index) = _dyld_get_image_name;
const char* lcMainBundlePath = NULL;

intptr_t (*orig_dyld_get_image_vmaddr_slide)(uint32_t image_index) = _dyld_get_image_vmaddr_slide;
const struct mach_header* (*orig_dyld_get_image_header)(uint32_t image_index) = _dyld_get_image_header;

// Rewritten
static void overwriteAppExecutableFileType(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct mach_header_64 *header = (struct mach_header_64*) orig_dyld_get_image_header(appMainImageIndex);
        kern_return_t kr = builtin_vm_protect(mach_task_self(), (vm_address_t)header, sizeof(header), false, PROT_READ | PROT_WRITE | VM_PROT_COPY);
        if(kr != KERN_SUCCESS)
            return;
        header->filetype = MH_EXECUTE;
        builtin_vm_protect(mach_task_self(), appMainImageIndex, sizeof(struct mach_header), false, PROT_READ);
    });
}
// Rewritten END

static inline int translateImageIndex(int origin)
{
    if(origin == lcImageIndex)
    {
        overwriteAppExecutableFileType();
        return appMainImageIndex;
    }
    return origin;
}

void* hook_dlsym(void * __handle, const char * __symbol)
{
    if(__handle == (void*)RTLD_MAIN_ONLY)
    {
        if(strcmp(__symbol, MH_EXECUTE_SYM) == 0)
        {
            overwriteAppExecutableFileType();
            return (void*)orig_dyld_get_image_header(appMainImageIndex);
        }
        __handle = appExecutableHandle;
    } else if (__handle != (void*)RTLD_SELF && __handle != (void*)RTLD_NEXT)
    {
        void* ans = orig_dlsym(__handle, __symbol);
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
    
    __attribute__((musttail)) return orig_dlsym(__handle, __symbol);
}

uint32_t hook_dyld_image_count(void)
{
    return orig_dyld_image_count() - 1 - (uint32_t)tweakLoaderLoaded;
}

const struct mach_header* hook_dyld_get_image_header(uint32_t image_index)
{
    __attribute__((musttail)) return orig_dyld_get_image_header(translateImageIndex(image_index));
}

intptr_t hook_dyld_get_image_vmaddr_slide(uint32_t image_index)
{
    __attribute__((musttail)) return orig_dyld_get_image_vmaddr_slide(translateImageIndex(image_index));
}

const char* hook_dyld_get_image_name(uint32_t image_index)
{
    __attribute__((musttail)) return orig_dyld_get_image_name(translateImageIndex(image_index));
}

void hideLiveContainerImageCallback(const struct mach_header* header, intptr_t vmaddr_slide)
{
    Dl_info info;
    dladdr(header, &info);
    if(!strncmp(info.dli_fname, lcMainBundlePath, strlen(lcMainBundlePath)) || strstr(info.dli_fname, "/procursus/") != 0) {
        char fakePath[PATH_MAX];
        snprintf(fakePath, sizeof(fakePath), "/usr/lib/%p.dylib", header);
        kern_return_t ret = vm_protect(mach_task_self(), (vm_address_t)info.dli_fname, PATH_MAX, false, PROT_READ | PROT_WRITE);
        if(ret != KERN_SUCCESS)
            os_thread_self_restrict_tpro_to_rw();
        strcpy((char *)info.dli_fname, fakePath);
        if(ret != KERN_SUCCESS)
            os_thread_self_restrict_tpro_to_ro();
    }
}

// Rewritten
bool hook_dyld_program_sdk_at_least(void* dyldApiInstancePtr, dyld_build_version_t version) {
    switch (version.platform) {
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
    *origFunction = (void*)*(void**)vtableFunctionPtr;
    *(uint64_t*)vtableFunctionPtr = (uint64_t)hookFunction;
    builtin_vm_protect(mach_task_self(), (mach_vm_address_t)vtableFunctionPtr, sizeof(uintptr_t), false, PROT_READ);
    return true;
}

bool initGuestSDKVersionInfo(void) {
    void* dyldBase = getDyldBase();
    const char* dyldPath = "/usr/lib/dyld";
    uint64_t offset = LCFindSymbolOffset(dyldPath, "__ZN5dyld3L11sVersionMapE");
    uint32_t *versionMapPtr = dyldBase + offset;
    assert(versionMapPtr);
    uint32_t* versionMapEnd = versionMapPtr + 2560;
    assert(versionMapPtr[0] == 0x07db0901 && versionMapPtr[2] == 0x00050000);
    uint32_t size = 0;
    for(int i = 1; i < 128; ++i)
    {
        if(versionMapPtr[i] == 0x07dc0901)
        {
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
    if (newVersionSetVersion == 0xffffffff && candidateVersion == 0)
        candidateVersionEquivalent = newVersionSetVersion;
    guestAppSdkVersionSet = candidateVersionEquivalent;
    return true;
}

void DyldHooksInit(void)
{
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
    orig_dyld_get_image_header = _dyld_get_image_header;
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, dlsym, hook_dlsym, nil);
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, _dyld_image_count, hook_dyld_image_count, nil);
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, _dyld_get_image_header, hook_dyld_get_image_header, nil);
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, _dyld_get_image_vmaddr_slide, hook_dyld_get_image_vmaddr_slide, nil);
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, _dyld_get_image_name, hook_dyld_get_image_name, nil);
    //_dyld_register_func_for_add_image((void (*)(const struct mach_header *, intptr_t))hideLiveContainerImageCallback);
    
    /*if(spoofSDKVersion)
    {
        guestAppSdkVersion = spoofSDKVersion;
        if(!initGuestSDKVersionInfo() ||
           !performHookDyldApi("dyld_program_sdk_at_least", 1, (void**)&orig_dyld_program_sdk_at_least, hook_dyld_program_sdk_at_least) ||
           !performHookDyldApi("dyld_get_program_sdk_version", 0, (void**)&orig_dyld_get_program_sdk_version, hook_dyld_get_program_sdk_version))
            return;
    }*/
}

void* getGuestAppHeader(void)
{
    return (void*)orig_dyld_get_image_header(appMainImageIndex);
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
    NSString *lockUnlockPtrName = @"dyld4::LibSystemHelpers::os_unfair_recursive_lock_lock_with_options";
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
