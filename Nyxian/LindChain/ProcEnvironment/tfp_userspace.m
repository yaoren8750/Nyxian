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

/*
 Header
 */
#import <LindChain/ProcEnvironment/environment.h>
#import <LindChain/ProcEnvironment/tfp_userspace.h>
#import <LindChain/ProcEnvironment/proxy.h>
#import <mach/mach.h>
#import <unistd.h>
#import <LindChain/litehook/src/litehook.h>
#import <dlfcn.h>

/*
 Internal Implementation
 */
static NSMutableDictionary <NSNumber*,RBSMachPort*> *tfp_userspace_ports;

kern_return_t environment_task_for_pid(mach_port_name_t taskPort,
                                       pid_t pid,
                                       mach_port_name_t *requestTaskPort)
{
    __block kern_return_t kr = KERN_SUCCESS;
    
    // Ignore input task port, literally take from `tfp_userspace_ports`
    RBSMachPort *machPortObject = [tfp_userspace_ports objectForKey:@(pid)];
    if(machPortObject)
    {
        if([machPortObject isUsable])
        {
            // We got machPortObject so insert it into `requestedTask`
            *requestTaskPort = [machPortObject port];
        }
        else
        {
            [tfp_userspace_ports removeObjectForKey:@(pid)];
            kr = KERN_FAILURE;
        }
    }
    else
    {
        if(environmentIsHost)
        {
            // No machPortObject, so deny
            kr = KERN_FAILURE;
        }
        else
        {
            [hostProcessProxy getPort:pid withReply:^(RBSMachPort *port){
                if(!port)
                {
                    kr = KERN_FAILURE;
                    dispatch_semaphore_signal(environment_semaphore);
                    return;
                }
                
                // We gather the port and save it!
                [tfp_userspace_ports setObject:port forKey:@(pid)];
                
                // now we set `requestTaskPort`
                *requestTaskPort = [port port];
                dispatch_semaphore_signal(environment_semaphore);
            }];
            dispatch_semaphore_wait(environment_semaphore, DISPATCH_TIME_FOREVER);
        }
    }
    
    return kr;
}

void handoff_task_for_pid(RBSMachPort *machPort)
{
    if([machPort isUsable])
    {
        pid_t pid = 0;
        kern_return_t kr = pid_for_task([machPort port], &pid);
        if(kr == KERN_SUCCESS) [tfp_userspace_ports setObject:machPort forKey:@(pid)];
    }
}

/*
 Init
 */
void tfp_userspace_init(BOOL host)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tfp_userspace_ports = [[NSMutableDictionary alloc] init];
        
        if(!host)
        {
            // MARK: Guest Init
            // MARK: TXM supported device is required to handoff task port to host app
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            BOOL alreadySucceeded = [defaults boolForKey:@"TXMOnlyActionTried"];
            BOOL alreadyTried     = [defaults boolForKey:@"TXMOnlyActionSuccessful"];
            if (alreadySucceeded || !alreadyTried) {
                if (!alreadySucceeded && !alreadyTried) {
                    [defaults setBool:YES forKey:@"TXMOnlyActionTried"];
                    [defaults synchronize];
                    [hostProcessProxy sendPort:[PrivClass(RBSMachPort) portForPort:mach_task_self()]];
                    [defaults setBool:YES forKey:@"TXMOnlyActionSuccessful"];
                    [defaults synchronize];
                } else {
                    [hostProcessProxy sendPort:[PrivClass(RBSMachPort) portForPort:mach_task_self()]];
                }
            }
            
            void *replacee = dlsym(RTLD_DEFAULT, "task_for_pid");
            litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, task_for_pid, environment_task_for_pid, nil);
        } else
        {
            // MARK: HOST Init
            // Insert our own mach port as "kernel mach port"
            [tfp_userspace_ports setObject:[PrivClass(RBSMachPort) portForPort:(mach_task_self())] forKey:@(0)];
        }
    });
}
