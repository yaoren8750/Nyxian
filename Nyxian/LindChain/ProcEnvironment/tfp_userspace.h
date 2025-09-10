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

// MARK: This needs TXM support on-device

#ifndef PROCENVIRONMENT_TFPUSERSPACE_H
#define PROCENVIRONMENT_TFPUSERSPACE_H

#import <Foundation/Foundation.h>
#import <LindChain/LiveContainer/UIKitPrivate.h>

kern_return_t task_for_pid(mach_port_name_t taskPort,
                           pid_t pid,
                           mach_port_name_t *requestTaskPort);
void handoff_task_for_pid(RBSMachPort *machPort);

void tfp_userspace_init(BOOL host);

#endif /* PROCENVIRONMENT_TFPUSERSPACE_H */
