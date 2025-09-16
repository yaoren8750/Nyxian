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

#import <LindChain/ProcEnvironment/environment.h>
#import <LindChain/ProcEnvironment/proxy.h>
#import <LindChain/ProcEnvironment/application.h>
#import <LindChain/litehook/src/litehook.h>
#import <LindChain/ObjC/Swizzle.h>
#import <dlfcn.h>

@interface UIApplication (ProcEnvironment)
@end

@implementation UIApplication (ProcEnvironment)

- (void)hook_run
{
    // Only allow client processing
    if(!environmentIsHost)
    {
        // Tell host app to let our process appear
        if(!environment_proxy_make_window_visible()) exit(0);
    }
    
    [self hook_run];
}

@end

/*
 Init
 */
void environment_application_init(BOOL host)
{
    if(!host)
    {
        // MARK: GUEST Init
        // MARK: Hooking _run of UIApplication class seems more reliable
        [ObjCSwizzler replaceInstanceAction:@selector(_run) ofClass:UIApplication.class withAction:@selector(hook_run)];
    }
}
