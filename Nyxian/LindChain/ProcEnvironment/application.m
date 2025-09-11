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

#import <LindChain/ProcEnvironment/application.h>
#import <LindChain/litehook/src/litehook.h>
#import <dlfcn.h>

static int (*real_UIApplicationMain)(int argc, char **argv, NSString *principalClassName, NSString *delegateClassName);

int environment_UIApplicationMain(int argc,
                                  char **argv,
                                  NSString *principalClassName,
                                  NSString *delegateClassName)
{
    NSLog(@"environment_UIApplicationMain: Hello, World!");
    return real_UIApplicationMain(argc, argv, principalClassName, delegateClassName);
}

/*
 Init
 */
void environment_application_init(BOOL host)
{
    if(!host)
    {
        // MARK: GUEST Init
        // MARK: This hook looks weirder than in tfp_userspace for example because LiveProcess is redifining alreay UIApplicationMain(), means it will reference to its UIApplicatioMain, which means that we have to resolve UIApplicationMain() at runtime
        void *addr = dlsym(RTLD_NEXT, "UIApplicationMain");
        real_UIApplicationMain = addr;
        litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, addr, environment_UIApplicationMain, nil);
    }
}
