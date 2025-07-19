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

#ifndef NYXIAN_ERRORTHROW_H
#define NYXIAN_ERRORTHROW_H

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

/// Function for throwing errors to JSContext
JSValue* jsDoThrowError(NSString *msg);

/// Premade errors
#define EW_ARGUMENT        @"Parameter failure"
#define EW_RUNTIME_SAFETY  @"Safety compromise detected, runtime safety is enabled, please disable it by calling disable_safety_checks();"
#define EW_UNEXPECTED      @"An unexpected mistake happened"
#define EW_PERMISSION      @"Permission denied"
#define EW_NULL_POINTER    @"Null pointer exception"
#define EW_OUT_OF_BOUNDS   @"Index out of bounds"
#define EW_MEMORY_LEAK     @"Memory leak detected"
#define EW_MEMORY_UAF      @"Attempt to use memory after freed detected"
#define EW_UNAUTHORIZED    @"Unauthorized access"
#define EW_INVALID_STATE   @"Invalid state encountered"
#define EW_TIMEOUT         @"Operation timed out"
#define EW_NETWORK_ERROR   @"Network error occurred"
#define EW_FILE_NOT_FOUND  @"File not found"
#define EW_INVALID_FORMAT  @"Invalid format"
#define EW_DIVIDE_BY_ZERO  @"Attempt to divide by zero"
#define EW_INTERNAL_ERROR  @"Internal error occurred"
#define EW_INVALID_INPUT   @"Invalid input provided"
#define EW_OVERFLOW        @"Buffer overflow detected"
#define EW_CONVERSION_ERROR @"Type conversion failed"
#define EW_RESOURCE_EXCEEDED @"Resource limit exceeded"
#define EW_UNSUPPORTED_OPERATION @"Operation not supported"
#define EW_DISK_FULL       @"Disk is full"
#define EW_UNKNOWN_ERROR   @"An unknown error occurred"
#define EW_MODULE_INCLUDE  @"Failed to include module"

/// Macro to automize symbol printint
#if __has_feature(objc_arc) && !defined(__cplusplus)
    #define JS_THROW_ERROR(msg) \
        jsDoThrowError([NSString stringWithFormat:@"%@ %@\n", NSStringFromSelector(_cmd), msg])
#else
    #define JS_THROW_ERROR(msg) \
        jsDoThrowError([NSString stringWithFormat:@"'%s': %@\n", __func__, msg])
#endif

NS_ASSUME_NONNULL_END

#endif
