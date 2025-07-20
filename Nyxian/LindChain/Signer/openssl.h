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
#include "common/json.h"

bool GetCertSubjectCN(const string &strCertData, string &strSubjectCN);
bool GetCMSInfo(uint8_t *pCMSData, uint32_t uCMSLength, JValue &jvOutput);
bool GetCMSContent(const string &strCMSDataInput, string &strContentOutput);
bool GenerateCMS(const string &strSignerCertData, const string &strSignerPKeyData, const string &strCDHashData, const string &strCDHashPlist, string &strCMSOutput);

class ZSignAsset
{
public:
	ZSignAsset();

public:
	bool GenerateCMS(const string &strCDHashData, const string &strCDHashesPlist, const string &strCodeDirectorySlotSHA1, const string &strAltnateCodeDirectorySlot256, string &strCMSOutput);
	bool Init();

public:
	string m_strTeamId;
	string m_strSubjectCN;
    string m_strCertData;
	string m_strProvisionData;
	string m_strEntitlementsData;
    string m_passData;
//    bool embedProvision;

private:
	void *m_evpPKey;
	void *m_x509Cert;
};
