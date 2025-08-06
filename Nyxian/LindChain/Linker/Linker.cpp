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

#include "lld/Common/Driver.h"
#include "lld/Common/ErrorHandler.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/Support/raw_ostream.h"

#include <vector>
#include <string>

extern "C" void ls_printf(const char *format, ...);

namespace lld {
namespace macho {

bool link(llvm::ArrayRef<const char *> args, llvm::raw_ostream &stdoutOS,
          llvm::raw_ostream &stderrOS, bool exitEarly, bool disableOutput);

} // namespace macho
} // namespace lld

extern "C" {

int linker(int argc, char **argv) {
    llvm::ArrayRef<const char*> args(argv, argc);
    
    std::string errBuffer;
    llvm::raw_string_ostream errStream(errBuffer);
    
    const lld::DriverDef drivers[] = {
        {lld::Darwin, &lld::macho::link},
    };

    lld::Result result = lld::lldMain(args, llvm::outs(), errStream, drivers);
    
    errStream.flush();
    
    ls_printf("%s", errBuffer.c_str());
    
    return result.retCode;
}

}
