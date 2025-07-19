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

#import <TwinterCore/Modules/IO/Types/Stat.h>
#import <sys/stat.h>

JSValue* buildStat(struct stat statStruct)
{
    JSValue *statObject = [JSValue valueWithNewObjectInContext:[JSContext currentContext]];
    
    JSValue *stATimespec = [JSValue valueWithNewObjectInContext:[JSContext currentContext]];
    stATimespec[@"tv_sec"] = @(statStruct.st_atimespec.tv_sec);
    stATimespec[@"tv_nsec"] = @(statStruct.st_atimespec.tv_nsec);
    
    JSValue *stMTimespec = [JSValue valueWithNewObjectInContext:[JSContext currentContext]];
    stMTimespec[@"tv_sec"] = @(statStruct.st_mtimespec.tv_sec);
    stMTimespec[@"tv_nsec"] = @(statStruct.st_mtimespec.tv_nsec);
    
    JSValue *stCTimespec = [JSValue valueWithNewObjectInContext:[JSContext currentContext]];
    stCTimespec[@"tv_sec"] = @(statStruct.st_ctimespec.tv_sec);
    stCTimespec[@"tv_nsec"] = @(statStruct.st_ctimespec.tv_nsec);
    
    JSValue *stBirthTimespec = [JSValue valueWithNewObjectInContext:[JSContext currentContext]];
    stBirthTimespec[@"tv_sec"] = @(statStruct.st_birthtimespec.tv_sec);
    stBirthTimespec[@"tv_nsec"] = @(statStruct.st_birthtimespec.tv_nsec);
    
    statObject[@"st_atimespec"] = stATimespec;
    statObject[@"st_mtimespec"] = stMTimespec;
    statObject[@"st_ctimespec"] = stCTimespec;
    statObject[@"st_birthtimespec"] = stBirthTimespec;
    statObject[@"st_blksize"] = @(statStruct.st_blksize);
    statObject[@"st_blocks"] = @(statStruct.st_blocks);
    statObject[@"st_ctimespec"] = @(statStruct.st_ctimespec.tv_sec);
    statObject[@"st_dev"] = @(statStruct.st_dev);
    statObject[@"st_flags"] = @(statStruct.st_flags);
    statObject[@"st_gen"] = @(statStruct.st_gen);
    statObject[@"st_gid"] = @(statStruct.st_gid);
    statObject[@"st_ino"] = @(statStruct.st_ino);
    statObject[@"st_lspare"] = @(statStruct.st_lspare);
    statObject[@"st_mode"] = @(statStruct.st_mode);
    statObject[@"st_mtimespec"] = @(statStruct.st_mtimespec.tv_sec);
    statObject[@"st_nlink"] = @(statStruct.st_nlink);
    
    // TODO: fix that please later, as it seems that this is not really compatible XD
    //statObject[@"st_qspare"] = @(statStruct.st_qspare);
    
    statObject[@"st_rdev"] = @(statStruct.st_rdev);
    statObject[@"st_size"] = @(statStruct.st_size);
    statObject[@"st_uid"] = @(statStruct.st_uid);
    
    return statObject;
}
