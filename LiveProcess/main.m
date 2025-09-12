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
#import "LindChain/LiveProcess/LDEApplicationWorkspaceInternal.h"
#import <LindChain/litehook/src/litehook.h>
#import <LindChain/ProcEnvironment/environment.h>
#import <LindChain/ProcEnvironment/proxy.h>

NSString* invokeAppMain(NSString *bundlePath,
                        NSString *homePath,
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

extern int LiveContainerMain(int argc, char *argv[]);
int LiveProcessMain(int argc, char *argv[]) {
    // Let NSExtensionContext initialize, once it's done it will call CFRunLoopStop
    CFRunLoopRun();
    
    // MARK: Its confirmed that it runs from here on
    NSDictionary *appInfo = LiveProcessHandler.retrievedAppInfo;
    
    // MARK: Tested it, the endpoint is definetly transmitted
    NSXPCListenerEndpoint* endpoint = appInfo[@"endpoint"];
    NSString *mode = appInfo[@"mode"];
    LDEApplicationObject *appObj = appInfo[@"appObject"];
    NSNumber *debugEnabled = appInfo[@"debugEnabled"];
    
    // Setting up environment
    environment_client_connect_to_host(endpoint);
    environment_init(NO);
    environment_client_attach_debugger();
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    if([mode isEqualToString:@"management"])
    {
        environment_client_handoff_standard_file_descriptors();
        [hostProcessProxy setLDEApplicationWorkspaceEndPoint:getLDEApplicationWorkspaceProxyEndpoint()];
        CFRunLoopRun();
    }
    else
    {
        // Handoff stdout and stderr output to host app
        // Debugging is only for applications
        if(debugEnabled.boolValue)
        {
            environment_client_attach_debugger();
            [hostProcessProxy getMemoryLogFDsForPID:getpid() withReply:^(NSFileHandle *stdoutHandle){
                handoffOutput(stdoutHandle.fileDescriptor);
                dispatch_semaphore_signal(sema);
            }];
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        } else {
            environment_client_handoff_standard_file_descriptors();
        }
        
        // MARK: Keep it alive
        char *argv[1] = { NULL };
        int argc = 0;
        NSString *error = invokeAppMain(appObj.bundlePath, appObj.containerPath, argc, argv);
        NSLog(@"invokeAppMain() failed with error: %@\nGuest app shutting down", error);
    }
    
    return 0;
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
