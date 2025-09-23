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

#import <Foundation/Foundation.h>
#include <stdint.h>

typedef NS_OPTIONS(uint64_t, PEEntitlement) {
    PEEntitlementGetHostTaskPortAllowed =    1ull << 0,
    PEEntitlementTaskForPidAllowed =         1ull << 1,
    PEEntitlementSurfaceWROnly =             1ull << 2,
    PEEntitlementSurfaceRDOnly =             1ull << 3,
    PEEntitlementSurfaceRW     =             (PEEntitlementSurfaceWROnly | PEEntitlementSurfaceRDOnly),
    PEEntitlementSetUidAllowed =             1ull << 4,
    PEEntitlementSetGidAllowed =             1ull << 5,
    PEEntitlementSendSignal    =             1ull << 6,
    PEEntitlementRecvSignal    =             1ull << 7,
    PEEntitlementSpawnProc     =             1ull << 8
};

#define PEEntitlementDefault PEEntitlementTaskForPidAllowed | PEEntitlementSurfaceRDOnly | PEEntitlementSendSignal | PEEntitlementRecvSignal | PEEntitlementSpawnProc
