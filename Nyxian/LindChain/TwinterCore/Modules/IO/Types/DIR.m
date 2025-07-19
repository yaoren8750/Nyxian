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

#import <TwinterCore/Modules/IO/Types/DIR.h>
#import <TwinterCore/Modules/IO/Helper/NSStringCpy.h>
#import <TwinterCore/Modules/IO/Helper/UniOrigHolder.h>

JSValue* buildDIR(DIR *directory)
{
    JSValue *dirObject = [JSValue valueWithNewObjectInContext:[JSContext currentContext]];
    
    UniversalOriginalHolder *Holder = [[UniversalOriginalHolder alloc] init:directory];
    
    dirObject[@"__orig"] = [JSValue valueWithObject:Holder inContext:[JSContext currentContext]];
    dirObject[@"__dd_fd"] = @(directory->__dd_fd);
    dirObject[@"__dd_loc"] = @(directory->__dd_loc);
    dirObject[@"__dd_size"] = @(directory->__dd_size);
    dirObject[@"__dd_buf"] = @(directory->__dd_buf);
    dirObject[@"__dd_len"] = @(directory->__dd_len);
    dirObject[@"__dd_seek"] = @(directory->__dd_seek);
    dirObject[@"__padding"] = @(directory->__padding);
    dirObject[@"__dd_flags"] = @(directory->__dd_flags);
    
    return dirObject;
}

void updateDIR(DIR *directory, JSValue *dirObject)
{
    UniversalOriginalHolder *Holder = [[UniversalOriginalHolder alloc] init:directory];
    
    dirObject[@"__orig"] = [JSValue valueWithObject:Holder inContext:[JSContext currentContext]];
    dirObject[@"__dd_fd"] = @(directory->__dd_fd);
    dirObject[@"__dd_loc"] = @(directory->__dd_loc);
    dirObject[@"__dd_size"] = @(directory->__dd_size);
    dirObject[@"__dd_buf"] = @(directory->__dd_buf);
    dirObject[@"__dd_len"] = @(directory->__dd_len);
    dirObject[@"__dd_seek"] = @(directory->__dd_seek);
    dirObject[@"__padding"] = @(directory->__padding);
    dirObject[@"__dd_flags"] = @(directory->__dd_flags);
}


DIR* buildBackDIR(JSValue *dirObject)
{
    JSValue *holderValue = dirObject[@"__orig"];
    UniversalOriginalHolder *Holder = [holderValue toObject];
    return Holder.ptr;
}
