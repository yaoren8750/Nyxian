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
#import <LindChain/ProcEnvironment/tfp_userspace.h>
#import <LindChain/ProcEnvironment/proxy.h>
#import <mach/mach.h>
#import <unistd.h>

/*
 Internal Implementation
 */
static NSMutableDictionary <NSNumber*,RBSMachPort*> *tfp_userspace_ports;

kern_return_t task_for_pid(mach_port_name_t taskPort,
                           pid_t pid,
                           mach_port_name_t *requestTaskPort)
{
    kern_return_t kr = KERN_SUCCESS;
    
    // Ignore input task port, literally take from `tfp_userspace_ports`
    RBSMachPort *machPortObject = [tfp_userspace_ports objectForKey:@(pid)];
    if(machPortObject)
    {
        // We got machPortObject so insert it into `requestedTask`
        *requestTaskPort = [machPortObject port];
    }
    else
    {
        // No machPortObject, so deny
        kr = KERN_DENIED;
    }
    
    return kr;
}

void handoff_task_for_pid(RBSMachPort *machPort)
{
    if([machPort isUsable])
    {
        pid_t pid = 0;
        pid_for_task([machPort port], &pid);
        [tfp_userspace_ports setObject:machPort forKey:@(pid)];
    }
}

/*
 Init
 */
void tfp_userspace_init(BOOL host)
{
    if(host)
    {
        // Host Init
        tfp_userspace_ports = [[NSMutableDictionary alloc] init];
    }
    else
    {
        // Guest Init
        // TODO: Fixup guests `task_for_pid`
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
    }
}
