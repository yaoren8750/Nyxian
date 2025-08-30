//
//  serverDelegate.m
//  LiveContainer
//
//  Created by SeanIsTethered on 29.08.25.
//

#import "serverDelegate.h"

@implementation TestService

- (void)sendMessage:(NSString *)message withReply:(void (^)(NSString *))reply {
    printf("Extension has sent: %s\n",[message UTF8String]);
    reply(@"Extension I received ur message!\n");
}

@end

@implementation ServerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    printf("Extension tries to connect!\n");
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(TestServiceProtocol)];
    
    TestService *exportedObject = [TestService alloc];
    newConnection.exportedObject = exportedObject;
    
    [newConnection resume];
    
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
