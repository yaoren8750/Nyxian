#import "FoundationPrivate.h"
#import "LCMachOUtils.h"
#import "utils.h"

#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <objc/runtime.h>

#include <dlfcn.h>
#include <execinfo.h>
#include <signal.h>
#include <sys/mman.h>
#include <stdlib.h>
#include "../litehook/src/litehook.h"
#import "Tweaks/Tweaks.h"
#include <mach-o/ldsyms.h>
#import <LindChain/Services/applicationmgmtd/LDEApplicationObject.h>
#import <LindChain/ProcEnvironment/Surface/surface.h>

NSUserDefaults *lcUserDefaults;
NSBundle *lcMainBundle;
NSBundle *guestMainBundle;

static uint64_t rnd64(uint64_t v, uint64_t r) {
    r--;
    return (v + r) & ~r;
}

void overwriteMainCFBundle(void) {
    // Overwrite CFBundleGetMainBundle
    uint32_t *pc = (uint32_t *)CFBundleGetMainBundle;
    void **mainBundleAddr = 0;
    while (true) {
        uint64_t addr = aarch64_get_tbnz_jump_address(*pc, (uint64_t)pc);
        if (addr) {
            // adrp <- pc-1
            // tbnz <- pc
            // ...
            // ldr  <- addr
            mainBundleAddr = (void **)aarch64_emulate_adrp_ldr(*(pc-1), *(uint32_t *)addr, (uint64_t)(pc-1));
            break;
        }
        ++pc;
    }
    assert(mainBundleAddr != NULL);
    *mainBundleAddr = (__bridge void *)NSBundle.mainBundle._cfBundle;
}

void overwriteMainNSBundle(NSBundle *newBundle) {
    // Overwrite NSBundle.mainBundle
    // iOS 16: x19 is _MergedGlobals
    // iOS 17: x19 is _MergedGlobals+4

    lcMainBundle = [NSBundle mainBundle];
    
    NSString *oldPath = NSBundle.mainBundle.executablePath;
    uint32_t *mainBundleImpl = (uint32_t *)method_getImplementation(class_getClassMethod(NSBundle.class, @selector(mainBundle)));
    for (int i = 0; i < 20; i++) {
        void **_MergedGlobals = (void **)aarch64_emulate_adrp_add(mainBundleImpl[i], mainBundleImpl[i+1], (uint64_t)&mainBundleImpl[i]);
        if (!_MergedGlobals) continue;

        // In iOS 17, adrp+add gives _MergedGlobals+4, so it uses ldur instruction instead of ldr
        if ((mainBundleImpl[i+4] & 0xFF000000) == 0xF8000000) {
            uint64_t ptr = (uint64_t)_MergedGlobals - 4;
            _MergedGlobals = (void **)ptr;
        }

        for (int mgIdx = 0; mgIdx < 20; mgIdx++) {
            if (_MergedGlobals[mgIdx] == (__bridge void *)NSBundle.mainBundle) {
                _MergedGlobals[mgIdx] = (__bridge void *)newBundle;
                break;
            }
        }
    }
    
    assert(![NSBundle.mainBundle.executablePath isEqualToString:oldPath]);
    
    // Overwriting the process information from previous main bundle
    NSMutableArray<NSString *> *objcArgv = NSProcessInfo.processInfo.arguments.mutableCopy;
    objcArgv[0] = guestMainBundle.executablePath;
    [NSProcessInfo.processInfo performSelector:@selector(setArguments:) withObject:objcArgv];
    NSProcessInfo.processInfo.processName = guestMainBundle.infoDictionary[@"CFBundleExecutable"];
    *_CFGetProgname() = NSProcessInfo.processInfo.processName.UTF8String;
    Class swiftNSProcessInfo = NSClassFromString(@"_NSSwiftProcessInfo");
    if(swiftNSProcessInfo) {
        // Swizzle the arguments method to return the ObjC arguments
        SEL selector = @selector(arguments);
        method_setImplementation(class_getInstanceMethod(swiftNSProcessInfo, selector), class_getMethodImplementation(NSProcessInfo.class, selector));
    }
}

int hook__NSGetExecutablePath_overwriteExecPath(char*** dyldApiInstancePtr, char* newPath, uint32_t* bufsize) {
    assert(dyldApiInstancePtr != 0);
    char** dyldConfig = dyldApiInstancePtr[1];
    assert(dyldConfig != 0);
    
    char** mainExecutablePathPtr = 0;
    // mainExecutablePath is at 0x10 for iOS 15~18.3.2, 0x20 for iOS 18.4+
    if(dyldConfig[2] != 0 && dyldConfig[2][0] == '/') {
        mainExecutablePathPtr = dyldConfig + 2;
    } else if (dyldConfig[4] != 0 && dyldConfig[4][0] == '/') {
        mainExecutablePathPtr = dyldConfig + 4;
    } else {
        assert(mainExecutablePathPtr != 0);
    }

    kern_return_t ret = builtin_vm_protect(mach_task_self(), (mach_vm_address_t)mainExecutablePathPtr, sizeof(mainExecutablePathPtr), false, PROT_READ | PROT_WRITE);
    if(ret != KERN_SUCCESS) {
        assert(os_tpro_is_supported());
        os_thread_self_restrict_tpro_to_rw();
    }
    *mainExecutablePathPtr = newPath;
    if(ret != KERN_SUCCESS) {
        os_thread_self_restrict_tpro_to_ro();
    }

    return 0;
}

void overwriteExecPath(const char *newExecPath) {
    // dyld4 stores executable path in a different place (iOS 15.0 +)
    // https://github.com/apple-oss-distributions/dyld/blob/ce1cc2088ef390df1c48a1648075bbd51c5bbc6a/dyld/DyldAPIs.cpp#L802
    int (*orig__NSGetExecutablePath)(void* dyldPtr, char* buf, uint32_t* bufsize);
    performHookDyldApi("_NSGetExecutablePath", 2, (void**)&orig__NSGetExecutablePath, hook__NSGetExecutablePath_overwriteExecPath);
    _NSGetExecutablePath((char*)newExecPath, NULL);
    // put the original function back
    performHookDyldApi("_NSGetExecutablePath", 2, (void**)&orig__NSGetExecutablePath, orig__NSGetExecutablePath);
}

static void *getAppEntryPoint(void *handle) {
    uint32_t entryoff = 0;
    const struct mach_header_64 *header = (struct mach_header_64 *)getGuestAppHeader();
    uint8_t *imageHeaderPtr = (uint8_t*)header + sizeof(struct mach_header_64);
    struct load_command *command = (struct load_command *)imageHeaderPtr;
    for(int i = 0; i < header->ncmds > 0; ++i) {
        if(command->cmd == LC_MAIN) {
            struct entry_point_command ucmd = *(struct entry_point_command *)imageHeaderPtr;
            entryoff = ucmd.entryoff;
            break;
        }
        imageHeaderPtr += command->cmdsize;
        command = (struct load_command *)imageHeaderPtr;
    }
    assert(entryoff > 0);
    return (void *)header + entryoff;
}

NSString* invokeAppMain(NSString *executablePath,
                        int argc,
                        char *argv[])
{
    // Getting executable path from argv
    if(executablePath == nil) return @"No executable path";
    
    // Getting home path from envp, it is okay if its not present
    const char *home = getenv("HOME");
    
    // Getting guestMainBundle, if applicable
    // Now trying to get bundle
    // MARK: For some very stupid reason it returns a bundle eitherway, a none null value
    guestMainBundle = [[NSBundle alloc] initWithPathForMainBundle:[executablePath stringByDeletingLastPathComponent]];
    
    // Setup directories
    if(home)
    {
        NSString *homePath = [NSString stringWithCString:home encoding:NSUTF8StringEncoding];
        
        if(guestMainBundle.bundleIdentifier)
        {
            NSArray *dirList = @[@"Library/Caches", @"Documents", @"SystemData", @"Tmp"];
            for (NSString *dir in dirList)
                [[NSFileManager defaultManager] createDirectoryAtPath:[homePath stringByAppendingPathComponent:dir] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        // Setup environment variables
        setenv("CFFIXED_USER_HOME", homePath.UTF8String, 1);
        setenv("TMPDIR", [[NSString stringWithFormat:@"%@/Tmp", homePath] UTF8String], 1);
    }
    
    // Overwrite them better now?
    // MARK: We need to first actually overwrite executable path so dyld doesnt complain about @rpath stuff logically
    overwriteExecPath(executablePath.fileSystemRepresentation);
    
    // Overwriting guests main bundle if applicable
    if(guestMainBundle.bundleIdentifier)
    {
        overwriteMainNSBundle(guestMainBundle);
        overwriteMainCFBundle();
    }
    
    // Preload executable to bypass RT_NOLOAD
    appMainImageIndex = _dyld_image_count();
    void *appHandle = dlopenBypassingLock(executablePath.fileSystemRepresentation, RTLD_LAZY|RTLD_GLOBAL|RTLD_FIRST);
    appExecutableHandle = appHandle;
    const char *dlerr = dlerror();
    
    if (!appHandle || (uint64_t)appHandle > 0xf00000000000) {
        if (dlerr)
            return @(dlerr);
        return @"dlopen: an unknown error occurred";
    }
    
    NUDGuestHooksInit();
    SecItemGuestHooksInit();
    NSFMGuestHooksInit();
    UIKitGuestHooksInit();
    StoreKitHooks_init();
    initDead10ccFix();
    DyldHooksInit();

    // Find main()
    int (*appMain)(int, char**) = getAppEntryPoint(appHandle);
    if (!appMain)
        return @"Could not find the main entry point";

    return [NSString stringWithFormat:@"App returned from its main function with code %d.", appMain(argc, argv)];
}

static void exceptionHandler(NSException *exception) {
    NSString *error = [NSString stringWithFormat:@"%@\nCall stack: %@", exception.reason, exception.callStackSymbols];
    [lcUserDefaults setObject:error forKey:@"error"];
}
