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

/*
 Clang structure will be stored here
 */

#include <stdbool.h>

typedef struct {
    bool Overwrite;
    bool Value;
} TwinterBool_t;

typedef struct {
    TwinterBool_t DisableFree;
    TwinterBool_t RelocatablePCH;
    TwinterBool_t ShowHelp;
    TwinterBool_t ShowStats;
} FrontEndOpts_t;

typedef struct {
    FrontEndOpts_t FrontEndOpts;
} Clang_t;

