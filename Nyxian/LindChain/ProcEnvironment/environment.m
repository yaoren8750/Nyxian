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
#import <LindChain/ProcEnvironment/tfp_userspace.h>
#import <LindChain/ProcEnvironment/proxy.h>

BOOL environmentIsHost;

void environment_init(BOOL host)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tfp_userspace_init(host);
        environmentIsHost = host;
    });
}

void environment_handoffProxy(NSObject<ServerProtocol> *proxy)
{
    hostProcessProxy = proxy;
}
