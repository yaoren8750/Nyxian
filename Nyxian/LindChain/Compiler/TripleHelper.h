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

#ifndef NYXIAN_RUNTIME_TRIPPLE_HELPER_H
#define NYXIAN_RUNTIME_TRIPPLE_HELPER_H

#include <iostream>

///
/// Function to get the development version of the host
///
std::string getDevelopmentOSVersion(void);

///
/// MARK: Im usure if there are other architectures supported by iOS but for now.. this..
///
/// Function to get the triple of the iOS device host
///
std::string getHostTriple(void);

#endif /* NYXIAN_RUNTIME_TRIPPLE_HELPER_H */
