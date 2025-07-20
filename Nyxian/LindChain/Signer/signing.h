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

#pragma once
#include "openssl.h"

bool ParseCodeSignature(uint8_t *pCSBase);
bool SlotBuildEntitlements(const string &strEntitlements, string &strOutput);
bool SlotBuildDerEntitlements(const string &strEntitlements, string &strOutput);
bool SlotBuildRequirements(const string &strBundleID, const string &strSubjectCN, string &strOutput);
bool GetCodeSignatureCodeSlotsData(uint8_t *pCSBase, uint8_t *&pCodeSlots1, uint32_t &uCodeSlots1Length, uint8_t *&pCodeSlots256, uint32_t &uCodeSlots256Length);
bool SlotBuildCodeDirectory(bool bAlternate,
							uint8_t *pCodeBase,
							uint32_t uCodeLength,
							uint8_t *pCodeSlotsData,
							uint32_t uCodeSlotsDataLength,
							uint64_t execSegLimit,
							uint64_t execSegFlags,
							const string &strBundleId,
							const string &strTeamId,
							const string &strInfoPlistSHA,
							const string &strRequirementsSlotSHA,
							const string &strCodeResourcesSHA,
							const string &strEntitlementsSlotSHA,
							const string &strDerEntitlementsSlotSHA,
							bool isExecuteArch,
							string &strOutput);
bool SlotBuildCMSSignature(ZSignAsset *pSignAsset,
						   const string &strCodeDirectorySlot,
						   const string &strAltnateCodeDirectorySlot,
						   string &strOutput);
bool GetCodeSignatureExistsCodeSlotsData(uint8_t *pCSBase,
										 uint8_t *&pCodeSlots1Data,
										 uint32_t &uCodeSlots1DataLength,
										 uint8_t *&pCodeSlots256Data,
										 uint32_t &uCodeSlots256DataLength);
uint32_t GetCodeSignatureLength(uint8_t *pCSBase);
