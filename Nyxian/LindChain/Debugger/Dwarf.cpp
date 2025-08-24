//
//  Dwarf.cpp
//  Nyxian
//
//  Created by SeanIsTethered on 23.08.25.
//

#include "llvm/DebugInfo/DWARF/DWARFContext.h"
#include "llvm/DebugInfo/DWARF/DWARFUnit.h"
#include "llvm/DebugInfo/DWARF/DWARFDie.h"
#include "llvm/Object/ObjectFile.h"
#include <llvm/Object/MachO.h>
#include "llvm/Object/Binary.h"
#include "llvm/Support/Error.h"
#include <iostream>

extern "C" {
    
    const char *getExceptionFromObjectFile(const char *objectFilePath,
                                           const char *functionName,
                                           uint64_t offset)
    {
        // Buffer used to write dbg return info
        static char buf[1024];
        
        // Getting obj file representation by LLVM
        auto objOrErr = llvm::object::ObjectFile::createObjectFile(objectFilePath);
        if (!objOrErr)
            return NULL;
        
        llvm::object::ObjectFile* objFile = objOrErr->getBinary();
        
        // Get symbols of objFile
        bool found = false;
        llvm::Expected<unsigned long long> functionBase = NULL;
        for (const auto &sym : objFile->symbols()) {
            auto nameOrErr = sym.getName();
            functionBase = sym.getAddress();
            if(!nameOrErr || !functionBase || (nameOrErr->compare(functionName) != 0))
                continue;
            found = true;
            break;
        }
        if(!found) return NULL;
        
        // We found it we keep goind!
        // MARK: Function base is defined as `functionBase`, it is suppose to mark where the function beginns. My plan is to use offset to know where the exception exactly is in the file
        // MARK: WE know now exactly where the exception happened in the obj file
        uintptr_t exceptionAddressInObjFile = (functionBase.get() + offset) - 4;
        
        // Create dwarf context, so we can access the linetable
        auto dwarfContext = llvm::DWARFContext::create(*objFile);
        
        for (const auto &cu : dwarfContext->compile_units()) {
            const llvm::DWARFDebugLine::LineTable *lineTable = dwarfContext->getLineTableForUnit(cu.get());
            
            if(!lineTable)
                continue;
            
            for (const auto &row : lineTable->Rows) {
                const auto &fileEntry = lineTable->Prologue.FileNames[row.File];
                
                if(row.Address.Address >= exceptionAddressInObjFile)
                {
                    llvm::Expected<const char*> maybeStr = fileEntry.Name.getAsCString();
                    
                    if (maybeStr)
                    {
                        std::snprintf(buf, 1024, "Exception at: %s:%d", maybeStr.get(), row.Line);
                        return buf;
                    }
                }
            }
        }
        
        return NULL;
    }
    
}
