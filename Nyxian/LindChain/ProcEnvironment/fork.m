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

// MARK: The craziest thing to prove my skill level ever

#include <mach/mach.h>

void environment_fork(void)
{
    // MARK: Okay so now executing a task, huh?
    // MARK: We just need to get our hands onto a task right that belongs to no process the user needs, a brand new one
    // MARK: We also need the task right of the process requesting
    // MARK: We then suspend both processes(requesting and the one at fork stage) and then clear the entire task at fork stage and copy over vm map and thread states over
    // MARK: Mammut task
}
