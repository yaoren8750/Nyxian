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

#import <dlfcn.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <objc/runtime.h>
#import "serverDelegate.h"
#import "LindChain/Services/applicationmgmtd/LDEApplicationWorkspaceInternal.h"
#import <LindChain/litehook/src/litehook.h>
#import <LindChain/ProcEnvironment/environment.h>
#import <LindChain/ProcEnvironment/proxy.h>
#import <LindChain/ProcEnvironment/posix_spawn.h>
#import <LindChain/ProcEnvironment/Surface/surface.h>
#import <LindChain/ProcEnvironment/fd_map_object.h>

NSString* invokeAppMain(NSString *executablePath,
                        int argc,
                        char *argv[]);
bool performHookDyldApi(const char* functionName, uint32_t adrpOffset, void** origFunction, void* hookFunction);

@interface LiveProcessHandler : NSObject<NSExtensionRequestHandling>
@end
@implementation LiveProcessHandler
static NSExtensionContext *extensionContext;
static NSDictionary *retrievedAppInfo;
+ (NSExtensionContext *)extensionContext {
    return extensionContext;
}

+ (NSDictionary *)retrievedAppInfo {
    return retrievedAppInfo;
}

- (void)beginRequestWithExtensionContext:(NSExtensionContext *)context {
    extensionContext = context;
    retrievedAppInfo = [context.inputItems.firstObject userInfo];
    // Return control to LiveContainerMain
    CFRunLoopStop(CFRunLoopGetMain());
}
@end

void handoffOutput(int fd)
{
    dup2(fd, STDOUT_FILENO);
    dup2(fd, STDERR_FILENO);
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);
}

extern char **environ;
void clear_environment(void)
{
    while (environ[0] != NULL)
    {
        char *eq = strchr(environ[0], '=');
        if(eq)
        {
            size_t len = eq - environ[0];
            char key[len + 1];
            strncpy(key, environ[0], len);
            key[len] = '\0';
            unsetenv(key);
        }
        else
        {
            environ++;
        }
    }
}

void overwriteEnvironmentProperties(NSDictionary *enviroDict)
{
    clear_environment();
    if(enviroDict)
    {
        for (NSString *key in enviroDict)
        {
            NSString *value = enviroDict[key];
            setenv([key UTF8String], [value UTF8String], 0);
        }
    }
}

void createArgv(NSArray<NSString *> *arguments,
                int *argc,
                char ***argv) {
    if (!arguments) {
        *argc = 0;
        return;
    }
    
    NSInteger count = arguments.count;
    *argc = (int)count;
    
    *argv = malloc(sizeof(char *) * (count + 1));
    for (NSInteger i = 0; i < count; i++) {
        (*argv)[i] = strdup(arguments[i].UTF8String);
    }
    (*argv)[count] = NULL;
}

int LiveProcessMain(int argc, char *argv[]) {
    // Let NSExtensionContext initialize, once it's done it will call CFRunLoopStop
    CFRunLoopRun();
    NSDictionary *appInfo = LiveProcessHandler.retrievedAppInfo;
    
    // MARK: New API that will overtake the previous one
    NSXPCListenerEndpoint* endpoint = appInfo[@"endpoint"];
    NSString* executablePath = appInfo[@"executablePath"];
    NSString *mode = appInfo[@"mode"];
    NSDictionary *environmentDictionary = appInfo[@"environment"];
    NSArray *argumentDictionary = appInfo[@"arguments"];
    FDMapObject *mapObject = appInfo[@"mapObject"];
    NSNumber *ppid = appInfo[@"ppid"];
    
    // If no ppid was passed then we stop execution out of security reasons
    if(ppid == nil) exit(0);
    
    // Setup fd map
    if(mapObject) [mapObject apply_fd_map];
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);
    
    // Setting up environment
    environment_client_connect_to_host(endpoint);
    
    if(environmentDictionary && environmentDictionary.count > 0) overwriteEnvironmentProperties(environmentDictionary);
    if(argumentDictionary && argumentDictionary.count > 0) createArgv(argumentDictionary, &argc, &argv);
    
    if([mode isEqualToString:@"management"])
    {
        environment_init(PEEntitlementDefault, EnvironmentRoleGuest, EnvironmentRestrictionSystem, [[NSString stringWithFormat:@"%@/Documents/usr/libexec/applicationmgmtd", NSHomeDirectory()] UTF8String], ppid.intValue);
        [hostProcessProxy setLDEApplicationWorkspaceEndPoint:getLDEApplicationWorkspaceProxyEndpoint()];
        CFRunLoopRun();
    }
    else if([mode isEqualToString:@"spawn"])
    {
        // posix_spawn and similar implementation
        environment_init(PEEntitlementDefault, EnvironmentRoleGuest, EnvironmentRestrictionUser, [executablePath UTF8String], ppid.intValue);
        invokeAppMain(executablePath, argc, argv);
    }
    
    exit(0);
}

// this is our fake UIApplicationMain called from _xpc_objc_uimain (xpc_main)
__attribute__((visibility("default")))
int UIApplicationMain(int argc, char * argv[], NSString * principalClassName, NSString * delegateClassName) {
    return LiveProcessMain(argc, argv);
}

// NSExtensionMain will load UIKit and call UIApplicationMain, so we need to redirect it to our fake one
DEFINE_HOOK(dlopen, void*, (void* dyldApiInstancePtr, const char* path, int mode)) {
    if(path && !strcmp(path, "/System/Library/Frameworks/UIKit.framework/UIKit")) {
        // switch back to original dlopen
        performHookDyldApi("dlopen", 2, (void**)&orig_dlopen, orig_dlopen);
        // FIXME: may be incompatible with jailbreak tweaks?
        return RTLD_MAIN_ONLY;
    } else {
        __attribute__((musttail)) return orig_dlopen(dyldApiInstancePtr, path, mode);
    }
}

void hook_do_nothing(void) {}

// Extension entry point
int NSExtensionMain(int argc, char * argv[]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    method_setImplementation(class_getInstanceMethod(NSClassFromString(@"NSXPCDecoder"), @selector(_validateAllowedClass:forKey:allowingInvocations:)), (IMP)hook_do_nothing);
#pragma clang diagnostic pop
    // hook dlopen UIKit
    performHookDyldApi("dlopen", 2, (void**)&orig_dlopen, hook_dlopen);
    // call the real one
    int (*orig_NSExtensionMain)(int argc, char * argv[]) = dlsym(RTLD_NEXT, "NSExtensionMain");
    return orig_NSExtensionMain(argc, argv);
}
