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

#ifndef NYXIAN_MODULE_IO_H
#define NYXIAN_MODULE_IO_H

#import <TwinterCore/Modules/Module.h>
#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <Nyxian-Swift.h>
#import <TwinterCore/Modules/IO/Macro.h>

NS_ASSUME_NONNULL_BEGIN

/*
 @Brief JSExport Protocol for I/O Module
 */
@protocol IOModuleExport <JSExport>

///
/// These functions are the basic standard for Nyxian Runtime.
/// They are for the purpose to communicate with with the stdin
/// hook
///
- (NSString*)perror;
- (id)fsync:(int)fd;
JSExportAs(ftruncate, - (id)ftruncate:(int)fd offset:(UInt64)offset                                     );

///
/// These are basically macro redirections so Nyxian Runtime can
/// use these basic macros.
///
- (BOOL)S_ISDIR:(UInt64)m;
- (BOOL)S_ISREG:(UInt64)m;
- (BOOL)S_ISLNK:(UInt64)m;
- (BOOL)S_ISCHR:(UInt64)m;
- (BOOL)S_ISBLK:(UInt64)m;
- (BOOL)S_ISFIFO:(UInt64)m;
- (BOOL)S_ISSOCK:(UInt64)m;

///
/// Functions for basic file descriptor I/O
///
- (id)close:(int)fd;
- (id)stat:(int)fd;
- (id)remove:(NSString*)path;
- (id)rmdir:(NSString*)path;
- (id)chdir:(NSString*)path;
JSExportAs(open,    - (id)open:(NSString *)path withFlags:(int)flags perms:(UInt16)perms                );
JSExportAs(write,   - (id)write:(int)fd text:(NSString*)text size:(UInt64)size                          );
JSExportAs(read,    - (id)read:(int)fd size:(UInt64)size                                                );
JSExportAs(seek,    - (id)seek:(int)fd position:(UInt16)position flags:(int)flags                       );
JSExportAs(access,  - (id)access:(NSString*)path flags:(int)flags                                       );
JSExportAs(mkdir,   - (id)mkdir:(NSString*)path perms:(UInt16)perms                                     );
JSExportAs(chown,   - (id)chown:(NSString*)path uid:(int)uid gid:(int)gid                               );
JSExportAs(chmod,   - (id)chmod:(NSString*)path flags:(UInt16)flags                                     );

///
/// This is still work in progress, these symbols are to interact with
/// file pointers.
///
- (id)fclose:(JSValue*)fileObject;
- (id)fileno:(JSValue*)fileObject;
JSExportAs(fopen,   - (id)fopen:(NSString*)path mode:(NSString*)mode                                    );
JSExportAs(freopen, - (id)freopen:(NSString*)path mode:(NSString*)mode fileObject:(JSValue*)fileObject  );

///
/// Functions for basic directory I/O
///
- (id)opendir:(NSString*)path;
- (id)closedir:(JSValue*)DIR_obj;
- (id)readdir:(JSValue*)DIR_obj;
- (id)rewinddir:(JSValue*)DIR_obj;

///
/// Functions to deal with environment variables
///
- (id)getenv:(NSString*)env;
- (id)unsetenv:(NSString*)env;
- (id)getcwd:(UInt64)size;
JSExportAs(setenv,  - (id)setenv:(NSString*)env value:(NSString*)value overwrite:(UInt32)overwrite      );

@end

/*
 @Brief I/O Module Interface
 */
@interface IOModule : Module <IOModuleExport>

@property (nonatomic, strong) NSMutableArray<NSNumber *> *array;

- (instancetype)init;

@end

NS_ASSUME_NONNULL_END

#endif /* NYXIAN_MODULE_IO_H */
