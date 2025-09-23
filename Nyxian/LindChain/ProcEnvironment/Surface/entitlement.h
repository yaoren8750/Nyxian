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
    PEEntitlementTaskForPid =                1ull << 1, // Grants getting task ports of other processes either with the same main priveleges or lower
    PEEntitlementTaskForPidSpecial =         1ull << 2, // Grants getting task ports of all other processes also processes with higher priveleges, but not host task port (needs PEEntitlementTaskForPid to work)
    PEEntitlementGetHostTaskPort =           1ull << 3, // Grants getting host task port (needs PEEntitlementTaskForPid to work)
    PEEntitlementTaskForPidAll =             (PEEntitlementGetHostTaskPort | PEEntitlementTaskForPidSpecial | PEEntitlementTaskForPid),
    
    /* Surface system */
    PEEntitlementSurfaceWROnly =             1ull << 3, // Grants write access onto the surface
    PEEntitlementSurfaceRDOnly =             1ull << 4, // Grants read access onto the surface (Note: rapid changes at runtime require iOS 26 because this is the only way to safely ensure these entitlements can be dropped when lost)
    PEEntitlementSurfaceRW     =             (PEEntitlementSurfaceWROnly | PEEntitlementSurfaceRDOnly),
    
    /* Main privilege system*/
    PEEntitlementSetUidAllowed =             1ull << 5, // Grants setting uid
    PEEntitlementSetGidAllowed =             1ull << 6, // Grants setting gid
    
    /* Signal system */
    PEEntitlementRecvSignal    =             1ull << 7, // Grants receiving signals
    PEEntitlementSendSignal    =             1ull << 8, // Grants sending signals
    
    /* Spawn system */
    PEEntitlementSpawnProc     =             1ull << 9  // Grants spawning processes
};

#define PEEntitlementDefault PEEntitlementTaskForPidAllowed | PEEntitlementSurfaceRDOnly | PEEntitlementSendSignal | PEEntitlementRecvSignal | PEEntitlementSpawnProc

bool proc_got_entitlement(pid_t pid, PEEntitlement entitlement);

#endif /* PROC_ENTITLEMENT_H */
