//
//  main.m
//  LiveProcess
//
//  Created by Duy Tran on 3/5/25.
//

#import <dlfcn.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <objc/runtime.h>
#import "serverDelegate.h"
#import "LindChain/LiveContainer/exec.h"

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

extern int LiveContainerMain(int argc, char *argv[]);
int LiveProcessMain(int argc, char *argv[]) {
    // Let NSExtensionContext initialize, once it's done it will call CFRunLoopStop
    CFRunLoopRun();
    
    // MARK: Its confirmed that it runs from here on
    NSDictionary *appInfo = LiveProcessHandler.retrievedAppInfo;
    
    // MARK: Tested it, the endpoint is definetly transmitted
    NSXPCListenerEndpoint* endpoint = appInfo[@"endpoint"];
    NSString *payloadPath = appInfo[@"payload"];
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithListenerEndpoint:endpoint];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(TestServiceProtocol)];
    connection.interruptionHandler = ^{
        NSLog(@"Connection to app interrupted");
        exit(0);
    };
    connection.invalidationHandler = ^{
        NSLog(@"Connection to app invalidated");
        exit(0);
    };
    
    [connection activate];
    
    NSObject<TestServiceProtocol> *proxy = [connection remoteObjectProxy];
    
    __block NSData *payload;
    __block NSData *certificateData;
    __block NSString *certificatePassword;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [proxy getFileHandleOfServerAtPath:payloadPath withServerReply:^(NSFileHandle *fileHandle){
        payload = [fileHandle readDataToEndOfFile];
        [proxy getCertiticateWithServerReply:^(NSData *sCertificateData, NSString *sCertificatePassword){
            certificateData = sCertificateData;
            certificatePassword = sCertificatePassword;
            [proxy sendMessage:[NSString stringWithFormat:@"Payload: %@", payload] withReply:^(NSString *serverSaid) {}];
            [proxy sendMessage:[NSString stringWithFormat:@"Crt: %@", certificateData] withReply:^(NSString *serverSaid) {}];
            [proxy sendMessage:[NSString stringWithFormat:@"Pwd: %@", certificatePassword] withReply:^(NSString *serverSaid) {}];
            dispatch_semaphore_signal(semaphore);
        }];
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    // MARK: Keep it alive
    exec(proxy, payload, certificateData, certificatePassword);
    
    return 0;
}

// this is our fake UIApplicationMain called from _xpc_objc_uimain (xpc_main)
__attribute__((visibility("default")))
int UIApplicationMain(int argc, char * argv[], NSString * principalClassName, NSString * delegateClassName) {
    return LiveProcessMain(argc, argv);
}

// NSExtensionMain will load UIKit and call UIApplicationMain, so we need to redirect it to our fake one
static void* (*orig_dlopen)(void* dyldApiInstancePtr, const char* path, int mode);
static void* hook_dlopen(void* dyldApiInstancePtr, const char* path, int mode) {
    const char *UIKitFrameworkPath = "/System/Library/Frameworks/UIKit.framework/UIKit";
    if(path && !strncmp(path, UIKitFrameworkPath, strlen(UIKitFrameworkPath))) {
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
