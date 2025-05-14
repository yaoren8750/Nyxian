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
#include "archo.h"

class ZMachO
{
public:
	ZMachO();
	~ZMachO();

public:
	bool Init(const char *szFile);
	bool InitV(const char *szFormatPath, ...);
	bool Free();
	void PrintInfo();
	bool Sign(ZSignAsset *pSignAsset, bool bForce, string strBundleId, string strInfoPlistSHA1, string strInfoPlistSHA256, const string &strCodeResourcesData);
	bool InjectDyLib(bool bWeakInject, const char *szDyLibPath, bool &bCreate);

private:
	bool OpenFile(const char *szPath);
	bool CloseFile();

	bool NewArchO(uint8_t *pBase, uint32_t uLength);
	void FreeArchOes();
	bool ReallocCodeSignSpace();

private:
	size_t m_sSize;
	string m_strFile;
	uint8_t *m_pBase;
	bool m_bCSRealloced;
	vector<ZArchO *> m_arrArchOes;
};
