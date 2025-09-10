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

#import "serverDelegate.h"
#import <LindChain/LiveContainer/LCUtils.h>
#import "LindChain/LiveProcess/LDEApplicationWorkspace.h"
#import <LindChain/Multitask/LDEMultitaskManager.h>
#import <LindChain/ProcEnvironment/tfp_userspace.h>

/*
 Server
 */
@implementation TestService

- (instancetype)init
{
    self = [super init];
    self.ports = [[NSMutableDictionary alloc] init];
    return self;
}

- (void)getFileHandleOfServerAtPath:(NSString *)path withServerReply:(void (^)(NSFileHandle *))reply
{
    printf("[Host App] Guest app requested file handle for %s\n", [path UTF8String]);
    reply([NSFileHandle fileHandleForReadingAtPath:path]);
}

- (void)getStdoutOfServerViaReply:(void (^)(NSFileHandle *))reply
{
    reply([[NSFileHandle alloc] initWithFileDescriptor:STDOUT_FILENO]);
}

- (void)getMemoryLogFDsForPID:(pid_t)pid withReply:(void (^)(NSFileHandle *))reply
{
    NSString *bundleIdentifier = [[LDEMultitaskManager shared] bundleIdentifierForProcessIdentifier:pid];
    if(bundleIdentifier)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            LogTextView *textLog = [[LogTextView alloc] init];
            [[LDEMultitaskManager shared] attachView:textLog toWindowGroupOfBundleIdentifier:bundleIdentifier withTitle:@"Log"];
            int fd = textLog.pipe.fileHandleForWriting.fileDescriptor;
            reply([[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:NO]);
        });
    } else {
        reply(nil);
    }
}

- (void)setLDEApplicationWorkspaceEndPoint:(NSXPCListenerEndpoint*)endpoint
{
    LDEApplicationWorkspace *workspace = [LDEApplicationWorkspace shared];
    if(workspace.proxy == nil)
    {
        NSXPCConnection* connection = [[NSXPCConnection alloc] initWithListenerEndpoint:endpoint];
        connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LDEApplicationWorkspaceProxyProtocol)];
        connection.interruptionHandler = ^{
            NSLog(@"Connection to LDEApplicationWorkspaceProxy interrupted");
        };
        connection.invalidationHandler = ^{
            NSLog(@"Connection to LDEApplicationWorkspaceProxy invalidated");
        };
        
        [connection activate];
        [[LDEApplicationWorkspace shared] setProxy:[connection remoteObjectProxy]];
    }
}

- (void)sendPort:(RBSMachPort*)machPort
{
    handoff_task_for_pid(machPort);
}

@end

@implementation ServerDelegate

- (instancetype)init
{
    self = [super init];
    _globalProxy = [[TestService alloc] init];
    return self;
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(TestServiceProtocol)];
    
    TestService *exportedObject = _globalProxy;
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
        sharedInstance.serverDelegate = [[ServerDelegate alloc] init];
        sharedInstance.listener = [sharedInstance.serverDelegate createAnonymousListener];
    });
    return sharedInstance;
}

- (NSXPCListenerEndpoint*)getEndpointForNewConnections
{
    NSXPCListenerEndpoint *endpoint = self.listener.endpoint;
    return endpoint;
}

@end
