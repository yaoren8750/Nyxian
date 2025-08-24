/*
 Copyright (C) 2025 cr4zyengineer
 Copyright (C) 2025 expo

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
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

#import <Compiler/Compiler.h>
#import <Private/LSApplicationWorkspace.h>
#import <Synpush/Synpush.h>
#import <LogService/LogService.h>
#import <Private/Restart.h>
#import <Downloader/fdownload.h>
#import <Linker/linker.h>
#import <LiveContainer/LCAppInfo.h>
#import <LiveContainer/LCUtils.h>
#import <LiveContainer/ZSign/zsigner.h>
#import <LiveContainer/LCMachOUtils.h>
#import "Debugger/Logger.h"
#import <Debugger/Log.h>

NSString* invokeAppMain(NSString *bundlePath, NSString *homePath, int argc, char *argv[]);
NSString* invokeBinaryMain(NSString *bundlePath, int argc, char *argv[]);
void addr_to_line(const char *binaryPath);
void checkDWARFSection(const char* path);

const char *getExceptionFromObjectFile(const char *objectFilePath,
                                       const char *functionName,
                                       uint64_t offset);
