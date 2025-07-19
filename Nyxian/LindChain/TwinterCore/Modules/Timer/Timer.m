/*
 Copyright (C) 2025 SeanIsTethered

 This file is part of Nyxian.

 FridaCodeManager is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 FridaCodeManager is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with FridaCodeManager. If not, see <https://www.gnu.org/licenses/>.
*/

#import <TwinterCore/Modules/Timer/Timer.h>
#import <mach/mach_time.h>

@implementation TimerModule

- (instancetype)init
{
    self = [super init];
    return self;
}

/// Better way to sleep than sleep :3
- (void)wait:(double)seconds
{
    // First of all we need a semaphore
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    // Now we create a delay with the passed argument of seconds by the user
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC));
    
    // We scheduling now when the execution should be dispatched
    dispatch_after(delay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Now it't time to signal the semaphore that is waiting
        dispatch_semaphore_signal(semaphore);
    });

    // We are waiting here till we get signaled by the scheduled dispatch
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

@end
