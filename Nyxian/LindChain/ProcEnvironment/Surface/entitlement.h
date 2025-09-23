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

#ifndef PROC_ENTITLEMENT_H
#define PROC_ENTITLEMENT_H

#import <Foundation/Foundation.h>
#include <stdint.h>

typedef NS_OPTIONS(uint64_t, PEEntitlement) {
    /* Task port system*/
    PEEntitlementTaskForPid =                1ull << 0, // Grants getting task ports of other processes either with the same main priveleges or lower
    PEEntitlementTaskForPidPrvt =            1ull << 1, // Grants getting task ports of all other processes also processes with higher priveleges, but not host task port (needs PEEntitlementTaskForPid to work)
    PEEntitlementGetHostTaskPort =           1ull << 2, // Grants getting host task port (needs PEEntitlementTaskForPid to work)
    PEEntitlementTaskForPidAll =             (PEEntitlementGetHostTaskPort | PEEntitlementTaskForPidPrvt | PEEntitlementTaskForPid),
    
    /* Surface system */
    PEEntitlementSurfaceRead =               1ull << 3, // Grants read access onto the surface (Note: rapid changes at runtime require iOS 26 because this is the only way to safely ensure these entitlements can be dropped when lost)
    
    /* Main privilege system*/
    PEEntitlementSetUidAllowed =             1ull << 4, // Grants setting uid
    PEEntitlementSetGidAllowed =             1ull << 5, // Grants setting gid
    
    /* Signal system */
    PEEntitlementRecvSignal    =             1ull << 6, // Grants receiving signals
    PEEntitlementSendSignal    =             1ull << 7, // Grants sending signals
    PEEntitlementSendSignalPrvt =            1ull << 8, // Grants sending signals to processes that dont have PEEntitlementRecvSignal and processes that have more main permitives
    
    /* Spawn system */
    PEEntitlementSpawnProc     =             1ull << 9  // Grants spawning processes
};

#define PEEntitlementNone 0
#define PEEntitlementDefault PEEntitlementTaskForPid | PEEntitlementSurfaceRead | PEEntitlementSendSignal | PEEntitlementRecvSignal | PEEntitlementSpawnProc
#define PEEntitlementAll PEEntitlementTaskForPid | PEEntitlementTaskForPidPrvt | PEEntitlementGetHostTaskPort | PEEntitlementTaskForPidAll | PEEntitlementSurfaceRead | PEEntitlementSetUidAllowed | PEEntitlementSetGidAllowed | PEEntitlementRecvSignal | PEEntitlementSendSignal | PEEntitlementSpawnProc

bool proc_got_entitlement(pid_t pid, PEEntitlement entitlement);

bool entitlement_got_entitlement(PEEntitlement present, PEEntitlement needed);

#endif /* PROC_ENTITLEMENT_H */
