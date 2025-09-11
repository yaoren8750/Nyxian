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

#ifndef PROCENVIRONMENT_SERVER_SERVERPROTOCOL_H
#define PROCENVIRONMENT_SERVER_SERVERPROTOCOL_H

#import <Foundation/Foundation.h>
#import <LindChain/Private/UIKitPrivate.h>
#import <LindChain/Multitask/LDEProcessManager.h>

@protocol ServerProtocol

- (void)getStdoutOfServerViaReply:(void (^)(NSFileHandle *))reply;
- (void)getMemoryLogFDsForPID:(pid_t)pid withReply:(void (^)(NSFileHandle *))reply;
- (void)setLDEApplicationWorkspaceEndPoint:(NSXPCListenerEndpoint*)endpoint;

/*
 tfp_userspace
 */
- (void)sendPort:(RBSMachPort*)machPort;
- (void)getPort:(pid_t)pid withReply:(void (^)(RBSMachPort*))reply;

/*
 libproc_userspace
 */
- (void)proc_listallpidsViaReply:(void (^)(NSSet*))reply;
- (void)proc_getProcStructureForProcessIdentifier:(pid_t)pid withReply:(void (^)(LDEProcess*))reply;

/*
 application
 */
- (void)makeWindowVisibleForProcessIdentifier:(pid_t)processIdentifier withReply:(void (^)(BOOL))reply;

@end

#endif /* PROCENVIRONMENT_SERVER_SERVERPROTOCOL_H */
