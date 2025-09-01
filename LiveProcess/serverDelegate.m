//
//  serverDelegate.m
//  LiveContainer
//
//  Created by SeanIsTethered on 29.08.25.
//

#import "serverDelegate.h"
#import <LindChain/LiveContainer/LCUtils.h>

@implementation TestService

- (void)sendMessage:(NSString *)message {
    printf("[Guest App] %s\n",[message UTF8String]);
}

- (void)getFileHandleOfServerAtPath:(NSString *)path withServerReply:(void (^)(NSFileHandle *))reply
{
    printf("[Host App] Guest app requested file handle for %s\n", [path UTF8String]);
    reply([NSFileHandle fileHandleForReadingAtPath:path]);
}

@end

@implementation ServerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(TestServiceProtocol)];
    
    TestService *exportedObject = [TestService alloc];
    newConnection.exportedObject = exportedObject;
    
    [newConnection resume];
    
    printf("[Host App] Guest app connected\n");
    
    return YES;
}

- (NSXPCListener*)createAnonymousListener
{
    printf("creating new listener\n");
    NSXPCListener *listener = [NSXPCListener anonymousListener];
    listener.delegate = self;
    [listener resume];
    return listener;
}

@end

@implementation ServerManager

+ (instancetype)sharedManager {
    static ServerManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];

        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            sharedInstance.serverDelegate = [[ServerDelegate alloc] init];
            sharedInstance.listener = [sharedInstance.serverDelegate createAnonymousListener];
        //});
    });
    return sharedInstance;
}

- (NSXPCListenerEndpoint*)getEndpointForNewConnections
{
    NSXPCListenerEndpoint *endpoint = self.listener.endpoint;
    return endpoint;
}

@end
