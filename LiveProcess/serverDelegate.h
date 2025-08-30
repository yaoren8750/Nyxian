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
