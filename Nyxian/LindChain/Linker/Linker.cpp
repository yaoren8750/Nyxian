//
//  Linker.cpp
//  Nyxian
//
//  Created by SeanIsTethered on 09.07.25.
//

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
