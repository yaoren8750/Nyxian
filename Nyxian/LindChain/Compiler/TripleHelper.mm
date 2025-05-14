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

#import <UIKit/UIKit.h>
#include <iostream>
#include <Compiler/TripleHelper.h>

///
/// Function to get the development version of the host
///
std::string getDevelopmentOSVersion(void) {
    std::string result = "16.5";
    
    if (@available(iOS 16.5, *)) {
        return result;
    } else {
        result = [[[UIDevice currentDevice] systemVersion] UTF8String];
        return result;
    }
}

///
/// MARK: Im usure if there are other architectures supported by iOS but for now.. this..
///
/// Function to get the triple of the iOS device host
///
std::string getHostTriple(void) {
    return [[NSString stringWithFormat:@"arm64-apple-ios%s", getDevelopmentOSVersion().c_str()] UTF8String];
}
