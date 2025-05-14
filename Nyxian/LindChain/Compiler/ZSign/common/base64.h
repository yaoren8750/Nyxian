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

#include <string>
#include <vector>

using namespace std;

class ZBase64
{
public:
	ZBase64(void);
	~ZBase64(void);

public:
	const char *Encode(const char *szSrc, int nSrcLen = 0);
	const char *Encode(const string &strInput);
	const char *Decode(const char *szSrc, int nSrcLen = 0, int *pDecLen = NULL);
	const char *Decode(const char *szSrc, string &strOutput);

private:
	inline int GetB64Index(char ch);
	inline char GetB64char(int nIndex);

private:
	vector<char *> m_arrDec;
	vector<char *> m_arrEnc;
};
