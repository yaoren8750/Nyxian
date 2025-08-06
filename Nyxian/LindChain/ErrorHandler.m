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

#import <Foundation/Foundation.h>

void updateErrorOfPath(const char* filePath,
                       const char* content)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //UniLogClass *unilog = [UniLogClass alloc];
        //unilog = [unilog loadCurrentUnilog];
        
        NSString *nspath = [NSString stringWithCString:filePath encoding:NSUTF8StringEncoding];
        NSString *nscontent = [NSString stringWithCString:content encoding:NSUTF8StringEncoding];
        
        //[unilog cacheerrorWithPath:nspath
        //                   content:nscontent];
    });
}

void removeErrorOfPath(const char *filePath)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //UniLogClass *unilog = [UniLogClass alloc];
        //unilog = [unilog loadCurrentUnilog];
        
        NSString *nspath = [NSString stringWithCString:filePath encoding:NSUTF8StringEncoding];
        
        //[unilog uncacheerrorWithPath:nspath];
    });
}
