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

#import <TwinterCore/Modules/IO/Types/FILE.h>
#import <TwinterCore/Modules/IO/Helper/UniOrigHolder.h>
#import <TwinterCore/Modules/IO/Helper/NSStringCpy.h>

#import <TwinterCore/ErrorThrow.h>
#import <TwinterCore/ReturnObjBuilder.h>

JSValue* buildFILE(FILE *file)
{
    JSValue *fileObject = [JSValue valueWithNewObjectInContext:[JSContext currentContext]];
    
    UniversalOriginalHolder *Holder = [[UniversalOriginalHolder alloc] init:file];
    
    fileObject[@"__orig"] = [JSValue valueWithObject:Holder inContext:[JSContext currentContext]];
    fileObject[@"_p"] = [NSString stringWithFormat:@"%s", file->_p];
    fileObject[@"_r"] = @(file->_r);
    fileObject[@"_r"] = @(file->_w);
    fileObject[@"_flags"] = @(file->_flags);
    fileObject[@"_file"] = @(file->_file);
    
    JSValue *sbufObject = [JSValue valueWithNewObjectInContext:[JSContext currentContext]];
    sbufObject[@"_base"] = [NSString stringWithFormat:@"%s", file->_bf._base];
    sbufObject[@"_size"] = @(file->_bf._size);
    
    fileObject[@"_bf"] = sbufObject;
    fileObject[@"_lbfsize"] = @(file->_lbfsize);
    
    // now lets continue with the rest of the structure
    JSValue *sbufSecondObject = [JSValue valueWithNewObjectInContext:[JSContext currentContext]];
    sbufSecondObject[@"_base"] = [NSString stringWithFormat:@"%s", file->_ub._base];
    sbufSecondObject[@"_size"] = @(file->_ub._size);
    
    fileObject[@"_ub"] = sbufSecondObject;
    
    /*
     @Note if you can implement __sFILEX, here is the place
     */
    //fileObject[@"_extra"] = @(file->_extra);
    
    fileObject[@"_ur"] = @(file->_ur);
    fileObject[@"_ubuf"] = [NSString stringWithFormat:@"%s", file->_ubuf];
    fileObject[@"_nbuf"] = [NSString stringWithFormat:@"%s", file->_nbuf];
    
    JSValue *sbufThirdObject = [JSValue valueWithNewObjectInContext:[JSContext currentContext]];
    sbufThirdObject[@"_base"] = [NSString stringWithFormat:@"%s", file->_lb._base];
    sbufThirdObject[@"_size"] = @(file->_lb._size);
    
    fileObject[@"_ub"] = sbufSecondObject;
    fileObject[@"_blksize"] = @(file->_blksize);
    
    fileObject[@"_offset"] = @(file->_offset);
    
    return fileObject;
}

void updateFILE(FILE *file, JSValue *fileObject)
{
    UniversalOriginalHolder *Holder = [[UniversalOriginalHolder alloc] init:file];
    
    fileObject[@"__orig"] = [JSValue valueWithObject:Holder inContext:[JSContext currentContext]];
    fileObject[@"_p"] = [NSString stringWithFormat:@"%s", file->_p];
    fileObject[@"_r"] = @(file->_r);
    fileObject[@"_r"] = @(file->_w);
    fileObject[@"_flags"] = @(file->_flags);
    fileObject[@"_file"] = @(file->_file);
    
    JSValue *sbufObject = [JSValue valueWithNewObjectInContext:[JSContext currentContext]];
    sbufObject[@"_base"] = [NSString stringWithFormat:@"%s", file->_bf._base];
    sbufObject[@"_size"] = @(file->_bf._size);
    
    fileObject[@"_bf"] = sbufObject;
    fileObject[@"_lbfsize"] = @(file->_lbfsize);
    
    // who ever wanna implement cookie, have fun
    //fileObject[@"_cookie"] = @(file->_cookie);
    
    // now lets continue with the rest of the structure
    JSValue *sbufSecondObject = [JSValue valueWithNewObjectInContext:[JSContext currentContext]];
    sbufSecondObject[@"_base"] = [NSString stringWithFormat:@"%s", file->_ub._base];
    sbufSecondObject[@"_size"] = @(file->_ub._size);
    
    fileObject[@"_ub"] = sbufSecondObject;
    
    /*
     @Note if you can implement __sFILEX, here is the place
     */
    //fileObject[@"_extra"] = @(file->_extra);
    
    fileObject[@"_ur"] = @(file->_ur);
    fileObject[@"_ubuf"] = [NSString stringWithFormat:@"%s", file->_ubuf];
    fileObject[@"_nbuf"] = [NSString stringWithFormat:@"%s", file->_nbuf];
    
    JSValue *sbufThirdObject = [JSValue valueWithNewObjectInContext:[JSContext currentContext]];
    sbufThirdObject[@"_base"] = [NSString stringWithFormat:@"%s", file->_lb._base];
    sbufThirdObject[@"_size"] = @(file->_lb._size);
    
    fileObject[@"_ub"] = sbufSecondObject;
    fileObject[@"_blksize"] = @(file->_blksize);
    
    fileObject[@"_offset"] = @(file->_offset);
}

FILE* restoreFILE(JSValue *fileObject)
{
    JSValue *holderValue = fileObject[@"__orig"];
    UniversalOriginalHolder *Holder = [holderValue toObject];
    return Holder.ptr;
}
