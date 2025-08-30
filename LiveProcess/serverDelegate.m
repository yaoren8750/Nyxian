//
//  serverDelegate.m
//  LiveContainer
//
//  Created by SeanIsTethered on 29.08.25.
//

#import "serverDelegate.h"
#import <LindChain/LiveContainer/LCUtils.h>

@implementation TestService

- (void)sendMessage:(NSString *)message withReply:(void (^)(NSString *))reply {
    printf("[Guest App] %s\n",[message UTF8String]);
    reply(@"Extension I received ur message!\n");
}

- (void)getCertiticateWithServerReply:(void (^)(NSData *, NSString *))reply
{
    printf("[Host App] Guest app requested certificate data\n");
    // Literally sending certificate over to service
    reply(LCUtils.certificateData, LCUtils.certificatePassword);
}

- (void)getPayloadWithServerReply:(void (^)(NSData *))reply
{
    // Literally sending over Builder specified payload path mfckers!
    // FIXME: Not a fixme but in future implement sending of a zip payload from builder. so that the app extension doesnt need a shared document path.. it can just run the app
    printf("[Host App] Guest app requested payload\n");
    NSString *payloadPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"LDEPayloadPath"];
    reply([NSData dataWithContentsOfFile:payloadPath]);
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
