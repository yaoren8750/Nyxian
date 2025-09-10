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

#ifndef LDEPROCESSMANAGER_H
#define LDEPROCESSMANAGER_H

#import <Foundation/Foundation.h>
#import <LindChain/Private/FoundationPrivate.h>
#import <LindChain/LiveContainer/UIKitPrivate.h>

/*
 Process
 */
@interface LDEProcess : NSObject

@property (nonatomic,strong) NSExtension *extension;
@property (nonatomic,strong) RBSProcessHandle *processHandle;

// MARK: This will only be relevant for devices with TXM support
@property (nonatomic,strong) RBSMachPort *rbsTaskPort;

// Process properties
@property (nonatomic,strong) NSUUID *identifier;
@property (nonatomic,strong) NSString *executablePath;
@property (nonatomic) pid_t pid;
@property (nonatomic) uid_t uid;
@property (nonatomic) gid_t gid;

- (instancetype)initWithBundleIdentifier:(NSString*)bundleIdentifier;

// MARK: On devices with TXM support it will use `task_suspend()`,`task_resume()`,`task_terminate()` and on devices without `SIGSTOP`,`SIGCONT`,`SIGKILL`
- (BOOL)suspend;
- (BOOL)resume;
- (BOOL)terminate;

@end

/*
 Process Manager
 */
@interface LDEProcessManager : NSObject

@property (nonatomic) NSMutableArray<LDEProcess*> *processes;

- (instancetype)init;
+ (instancetype)shared;

- (pid_t)spawnProcessWithBundleIdentifier:(NSString *)bundleIdentifier;

@end

#endif /* LDEPROCESSMANAGER_H */
