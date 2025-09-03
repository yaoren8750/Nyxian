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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <LindChain/Debugger/Logger.h>

/*
 Server + Client Side
 */
@protocol TestServiceProtocol

- (void)getFileHandleOfServerAtPath:(NSString *)path withServerReply:(void (^)(NSFileHandle *))reply;
- (void)getStdoutOfServerViaReply:(void (^)(NSFileHandle *))reply;
- (void)getMemoryLogFDsForPID:(pid_t)pid withReply:(void (^)(NSFileHandle *))reply;
- (void)setLDEApplicationWorkspaceEndPoint:(NSXPCListenerEndpoint*)endpoint;

@end

/*
 Server Side aswell
 */
@interface TestService: NSObject <TestServiceProtocol>

@property (nonatomic) NSMutableDictionary<NSNumber*,LogTextView*> *textLogs;

- (void)getFileHandleOfServerAtPath:(NSString *)path withServerReply:(void (^)(NSFileHandle *))reply;
- (void)getStdoutOfServerViaReply:(void (^)(NSFileHandle *))reply;
- (void)getMemoryLogFDsForPID:(pid_t)pid withReply:(void (^)(NSFileHandle *))reply;
- (void)setLDEApplicationWorkspaceEndPoint:(NSXPCListenerEndpoint*)endpoint;

@end

/*
 Server Side
 */
@interface ServerDelegate : NSObject <NSXPCListenerDelegate>

@property (nonatomic,strong) TestService *globalProxy;

@end

@interface ServerManager : NSObject

@property (nonatomic,strong) ServerDelegate *serverDelegate;
@property (nonatomic,strong) NSXPCListener *listener;

+ (instancetype)sharedManager;
- (NSXPCListenerEndpoint*)getEndpointForNewConnections;
@end
