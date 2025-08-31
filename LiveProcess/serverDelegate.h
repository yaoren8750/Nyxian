//
//  serverDelegate.h
//  LiveContainer
//
//  Created by SeanIsTethered on 29.08.25.
//

#import <Foundation/Foundation.h>

/*
 Server + Client Side
 */
@protocol TestServiceProtocol

- (void)sendMessage:(NSString*)message withReply:(void(^)(NSString*))reply;
- (void)getCertiticateWithServerReply:(void(^)(NSData*,NSString*))reply;
- (void)getPayloadWithServerReply:(void (^)(NSData *))reply __attribute__((deprecated("Using getPayloadHandleWithServerReply: is generally faster for large payloads")));
- (void)getPayloadHandleWithServerReply:(void (^)(NSFileHandle*))reply;

@end

/*
 Server Side aswell
 */
@interface TestService: NSObject <TestServiceProtocol>
@end

/*
 Server Side
 */
@interface ServerDelegate : NSObject <NSXPCListenerDelegate>
@end

@interface ServerManager : NSObject
@property (nonatomic, strong) ServerDelegate *serverDelegate;
@property (nonatomic, strong) NSXPCListener *listener;
+ (instancetype)sharedManager;
- (NSXPCListenerEndpoint*)getEndpointForNewConnections;
@end
