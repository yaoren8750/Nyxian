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
#import <LindChain/ProcEnvironment/Object/MachPortObject.h>
#import <LindChain/ProcEnvironment/Object/MappingPortObject.h>
#import <LindChain/ProcEnvironment/Object/MachOObject.h>
#import <LindChain/ProcEnvironment/posix_spawn.h>
#import <LindChain/ProcEnvironment/Surface/surface.h>

typedef NS_OPTIONS(uint64_t, CredentialSet) {
    CredentialSetUID = 0,
    CredentialSetEUID = 1,
    CredentialSetRUID = 2,
    CredentialSetGID = 3,
    CredentialSetEGID = 4,
    CredentialSetRGID = 5,
    CredentialSetMAX = 6,
};

@protocol ServerProtocol

/*
 tfp_userspace
 */
- (void)sendPort:(MachPortObject*)machPort API_AVAILABLE(ios(26.0));
- (void)getPort:(pid_t)pid withReply:(void (^)(MachPortObject*))reply API_AVAILABLE(ios(26.0));

/*
 libproc_userspace
 */
- (void)proc_listallpidsViaReply:(void (^)(NSSet*))reply;
- (void)proc_getProcStructureForProcessIdentifier:(pid_t)pid withReply:(void (^)(LDEProcess*))reply;
- (void)proc_kill:(pid_t)pid withSignal:(int)signal withReply:(void (^)(int))reply;

/*
 application
 */
- (void)makeWindowVisibleWithReply:(void (^)(BOOL))reply;

/*
 posix_spawn
 */
- (void)spawnProcessWithPath:(NSString*)path withArguments:(NSArray*)arguments withEnvironmentVariables:(NSDictionary *)environment withMapObject:(FDMapObject*)mapObject withReply:(void (^)(pid_t))reply;

/*
 surface
 */
- (void)handinSurfaceMappingPortObjectViaReply:(void (^)(MappingPortObject *))reply;

/*
 Background mode fixup
 */
- (void)setAudioBackgroundModeActive:(BOOL)active;

/*
 Set credentials
 */
- (void)setCredentialWithOption:(CredentialSet)option withIdentifier:(uid_t)uid withReply:(void (^)(int result))reply;

/*
 Signer
 */
- (void)signMachO:(MachOObject*)object withReply:(void (^)(void))reply;

/*
 Launch Services
 */
- (void)setEndpoint:(NSXPCListenerEndpoint*)endpoint forServiceIdentifier:(NSString*)serviceIdentifier;
- (void)getEndpointOfServiceIdentifier:(NSString*)serviceIdentifier withReply:(void (^)(NSXPCListenerEndpoint *result))reply;

@end

#endif /* PROCENVIRONMENT_SERVER_SERVERPROTOCOL_H */
