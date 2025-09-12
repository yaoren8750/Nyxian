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
#import <LindChain/ProcEnvironment/tfp.h>
#import <LindChain/ProcEnvironment/proxy.h>
#import <mach/mach.h>
#import <unistd.h>
#import <LindChain/litehook/src/litehook.h>
#import <dlfcn.h>
#import <LindChain/ProcEnvironment/tfp_object.h>


/*
 Internal Implementation
 */
static NSMutableDictionary <NSNumber*,TaskPortObject*> *tfp_userspace_ports;

kern_return_t environment_task_for_pid(mach_port_name_t taskPort,
                                       pid_t pid,
                                       mach_port_name_t *requestTaskPort)
{
    __block kern_return_t kr = KERN_SUCCESS;
    
    // Ignore input task port, literally take from `tfp_userspace_ports`
    TaskPortObject *machPortObject = [tfp_userspace_ports objectForKey:@(pid)];
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
            [hostProcessProxy getPort:pid withReply:^(TaskPortObject *port){
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

void environment_host_take_client_task_port(TaskPortObject *machPort)
{
    if(!environmentIsHost) return;
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
void environment_tfp_init(BOOL host)
{
    // MARK: Apple seems to have implemented mach port transmission into iOS 26, as in iOS 18.7 RC and below it crashes but on iOS 26.0 RC it actually transmitts the task port
    if (@available(iOS 26.0, *)) {
        tfp_userspace_ports = [[NSMutableDictionary alloc] init];
        
        if(!host)
        {
            // MARK: Guest Init
            [hostProcessProxy sendPort:[[TaskPortObject alloc] initWithPort:mach_task_self()]];
            litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, task_for_pid, environment_task_for_pid, nil);
        }
        else
        {
            // MARK: HOST Init
            // Set kernel mach port to our host apps mach port
            [tfp_userspace_ports setObject:[[TaskPortObject alloc] initWithPort:mach_task_self()] forKey:@(0)];
        }
    }
    else
    {
        if(!host)
        {
            litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, environment_task_for_pid, task_for_pid, nil);
        }
    }
}
