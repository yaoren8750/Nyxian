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

#ifndef PROCENVIRONMENT_FD_H
#define PROCENVIRONMENT_FD_H

#import <LindChain/LiveContainer/Tweaks/libproc.h>

/*!
 @function get_all_fds
 @abstract Gets all file descriptors.
 @discussion
    Gets all file descriptors currently opened in the process.
 */
void get_all_fds(int *numFDs, struct proc_fdinfo **fdinfo);

/*!
 @function close_all_fd
 @abstract Closes all file descriptors.
 @discussion
    Closes all file descriptors using libproc.
 */
void close_all_fd(void);

#endif /* PROCENVIRONMENT_FD_H */
