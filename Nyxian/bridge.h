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

#import <LindChain/Compiler/Compiler.h>
#import <LindChain/Synpush/Synpush.h>
#import <LindChain/Downloader/fdownload.h>
#import <LindChain/Linker/linker.h>
#import <LindChain/LiveContainer/LCAppInfo.h>
#import <LindChain/LiveContainer/LCUtils.h>
#import <LindChain/LiveContainer/ZSign/zsigner.h>
#import <LindChain/LiveContainer/LCMachOUtils.h>
#import <LindChain/Debugger/Logger.h>
#import <LindChain/Multitask/LDEMultitaskManager.h>
#import <LindChain/Services/applicationmgmtd/LDEApplicationWorkspace.h>
#import <LindChain/LiveContainer/zip.h>
#import <LindChain/Private/UIKitPrivate.h>
#import <LindChain/Multitask/LDEProcessManager.h>
#import <LindChain/LiveContainer/ZSign/zsigner.h>
#import <LindChain/ProcEnvironment/Surface/surface.h>
#import <LindChain/ProcEnvironment/Server/Trust.h>

/*
 Project
 */
#import <Project/NXUser.h>
#import <Project/NXCodeTemplate.h>
#import <Project/NXPlistHelper.h>
#import <Project/NXProject.h>

/*
 Core
 */
#import <LindChain/Core/LDEThreadControl.h>

/*
 UI
 */
#import <UI/TableCells/NXProjectTableCell.h>

NSString* invokeAppMain(NSString *bundlePath, NSString *homePath, int argc, char *argv[]);
NSString* invokeBinaryMain(NSString *bundlePath, int argc, char *argv[]);
const char *getExceptionFromObjectFile(const char *objectFilePath,
                                       const char *functionName,
                                       uint64_t offset);
