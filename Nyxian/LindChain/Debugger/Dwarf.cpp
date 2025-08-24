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
        if (!objOrErr) {
            std::cerr << "Failed to open object file.\n";
            return NULL;
        }
        
        llvm::object::ObjectFile* objFile = objOrErr->getBinary();
        
        // Get symbols of objFile
        bool found = false;
        uintptr_t functionBase = 0x00;
        for (const auto &sym : objFile->symbols()) {
            // Prepare
            llvm::Expected<llvm::StringRef> nameOrErr = sym.getName();
            auto addrOrErr = sym.getAddress();
            if (!nameOrErr || !addrOrErr) continue;
            
            // Itterate through object file symbols
            if(std::strcmp(nameOrErr.get().str().c_str(), functionName) == 0)
            {
                functionBase = addrOrErr.get();
                found = true;
                break;
            }
        }
        
        // If we didnt found it we just return NULL
        if(!found) return NULL;
        
        // We found it we keep goind!
        // MARK: Function base is defined as `functionBase`, it is suppose to mark where the function beginns. My plan is to use offset to know where the exception exactly is in the file
        // MARK: WE know now exactly where the exception happened in the obj file
        uintptr_t exceptionAddressInObjFile = (functionBase + offset) - 4;
        
        // Create dwarf context, so we can access the linetable
        auto dwarfContext = llvm::DWARFContext::create(*objFile);
        
        for (const auto &cu : dwarfContext->compile_units()) {
            // The line table ;3
            const llvm::DWARFDebugLine::LineTable *lineTable = dwarfContext->getLineTableForUnit(cu.get());
            if (lineTable) {
                for (const auto &row : lineTable->Rows) {
                    const auto &fileEntry = lineTable->Prologue.FileNames[row.File];
                    
                    if(row.Address.Address >= exceptionAddressInObjFile)
                    {
                        llvm::Expected<const char*> maybeStr = fileEntry.Name.getAsCString();
                        
                        if (!maybeStr) {
                            std::cout << "Error: " << llvm::toString(maybeStr.takeError()) << "\n";
                        } else {
                            // MARK: We got em!
                            std::snprintf(buf, 1024, "Exception at: %s:%d", maybeStr.get(), row.Line);
                            std::printf("%s", buf);
                            return buf;
                        }
                    }
                }
            }
        }
        
        return NULL;
    }
    
    void addr_to_line(const char *binaryPath) {
        auto objOrErr = llvm::object::ObjectFile::createObjectFile(binaryPath);
        if (!objOrErr) {
            std::cerr << "Failed to open object file.\n";
            return;
        }
        
        llvm::object::ObjectFile* objFile = objOrErr->getBinary();
        
        for (const auto &sym : objFile->symbols()) {
            llvm::Expected<llvm::StringRef> nameOrErr = sym.getName();
            auto addrOrErr = sym.getAddress();
            if (!nameOrErr || !addrOrErr) continue;
            std::cout << nameOrErr.get().str().c_str() << " : 0x" << std::hex << addrOrErr.get() << "\n";
        }
        
        auto dwarfContext = llvm::DWARFContext::create(*objFile);
        
        for (const auto &cu : dwarfContext->compile_units()) {
            std::cout << "CU offset: 0x" << std::hex << cu->getOffset() << std::dec << "\n";
            std::cout << "  Version: " << cu->getVersion() << "\n";
            
            // Get the CU DIE and read DW_AT_producer
            llvm::DWARFDie cuDie = cu->getUnitDIE();
            if (cuDie) {
                if (auto producerAttr = cuDie.find(llvm::dwarf::DW_AT_producer)) {
                    llvm::Expected<const char*> maybeStr = producerAttr->getAsCString();
                    if (!maybeStr) {
                        std::cout << "Error: " << llvm::toString(maybeStr.takeError()) << "\n";
                    } else {
                        const char *producerStr = maybeStr.get();
                        std::cout << "  Producer: " << producerStr << "\n";
                    }
                }
            }
            
            // Print files in the line table
            // Access line table via DWARFContext
            const llvm::DWARFDebugLine::LineTable *lineTable = dwarfContext->getLineTableForUnit(cu.get());
            if (lineTable) {
                for (const auto &row : lineTable->Rows) {
                    const auto &fileEntry = lineTable->Prologue.FileNames[row.File];
                    llvm::Expected<const char*> maybeStr = fileEntry.Name.getAsCString();
                    if (!maybeStr) {
                        std::cout << "Error: " << llvm::toString(maybeStr.takeError()) << "\n";
                    } else {
                        std::cout << "Address: 0x" << std::hex << row.Address.Address
                        << " File: " << maybeStr.get()
                        << " Line: " << std::dec << row.Line << "\n";
                    }
                }
            }
            
            std::cout << "-----------------------------------\n";
        }
    }
    
    void checkDWARFSection(const char* path) {
        auto objOrErr = llvm::object::ObjectFile::createObjectFile(path);
        if (!objOrErr) {
            std::cerr << "Failed to open object file: "
            << llvm::toString(objOrErr.takeError()) << "\n";
            return;
        }
        
        llvm::object::ObjectFile* objFile = objOrErr->getBinary();
        bool foundDWARF = false;
        
        for (const auto &sec : objFile->sections()) {
            llvm::StringRef name;
            name = sec.getName().get();
            std::cout << name.str() << "\n";
            if (name.starts_with("__debug_")) {
                foundDWARF = true;
                std::cout << "Found DWARF section: " << name.str() << "\n";
            }
        }
        
        if (!foundDWARF)
            std::cout << "No DWARF sections found in " << path << "\n";
    }
}
