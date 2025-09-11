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

#ifndef PROCENVIRONMENT_LIBPROCUSERSPACE_H
#define PROCENVIRONMENT_LIBPROCUSERSPACE_H

#import <Foundation/Foundation.h>
#import <unistd.h>

extern NSMutableSet<NSNumber*> *environment_process_identifier;

void environment_register_process_identifier(pid_t process_identifier);
void environment_unregister_process_identifier(pid_t process_identifier);

void environment_libproc_userspace_init(BOOL host);

#endif /* PROCENVIRONMENT_LIBPROCUSERSPACE_H */
