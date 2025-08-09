/*
 Copyright (C) 2025 cr4zyengineer
 Copyright (C) 2025 expo

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

#import <Decompiler/Decompiler.h>
#include <iostream>

std::vector<std::string> disassembleARM64iOS(uint8_t* code, size_t codeSize);

@implementation Decompiler

+ (NSString*)decompileBinary:(uint8_t*)code withSize:(size_t)size
{
    std::vector<std::string> array = disassembleARM64iOS(code, size);
    NSMutableString *result = [NSMutableString string];
    for (size_t i = 0; i < array.size(); i++)
        [result appendFormat:@"%@\n", [NSString stringWithUTF8String:array[i].c_str()]];
    return result;
}

+ (NSString*)getDecompiledCodeBuffer:(UInt64)markAddress
{
    uint8_t *codeBuffer = ((uint8_t*)markAddress) - 32;
    size_t totalSize = 64;
    size_t instrSize = 4;

    std::vector<std::string> array = disassembleARM64iOS(codeBuffer, totalSize);

    NSMutableString *result = [NSMutableString string];
    for (size_t i = 0; i < array.size(); i++) {
        uint64_t currAddr = (uint64_t)(codeBuffer + i * instrSize);
        NSString *prefix = (currAddr == markAddress) ? @"-> " : @"   ";
        [result appendFormat:@"%@%@\n", prefix, [NSString stringWithUTF8String:array[i].c_str()]];
    }

    return result;
}

@end
