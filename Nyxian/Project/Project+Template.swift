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

import Foundation

class AppCodeTemplate {
    
    enum AppCodeTemplateScheme: String {
        case objc = "ObjC"
        case objclive = "ObjCTest"
        case binary = "Binary"
    }
    
    private func createAuthoredCodeFile(
        srcPath  spath: String,
        destPath dpath: String
    ) {
        // Check if source file exists
        guard FileManager.default.fileExists(atPath: spath) else { return }
        
        do {
            // Get its content
            let codeFileContent: String = try String(contentsOf: spath.URLGet(), encoding: .utf8)
            
            // Now append the author to it
            let authoredCodeFileContent: String = Author.shared.signatureForFile(dpath.URLLastPathComponent()).appending(codeFileContent)
            
            // Now write back
            try authoredCodeFileContent.write(to: dpath.URLGet(), atomically: true, encoding: .utf8)
        } catch {
            print(error)
        }
    }
    
    func createCode(
        withProjectName name: String,
        atPath path: String,
        withScheme scheme: AppCodeTemplateScheme
    ) {
        // check if destination exists
        guard FileManager.default.fileExists(atPath: path) else { return }
        
        // set author target
        Author.shared.setTargetProject(name)
        
        // set template path
        let templatePath: String = "\(Bundle.main.bundlePath)/Shared/Templates/\(scheme.rawValue)"
        
        do {
            // get entries
            let entries: [String] = try FileManager.default.contentsOfDirectory(atPath: templatePath)
            var allInclusiveEntries: [(String,String)] = []
            
            for entry in entries {
                allInclusiveEntries.append(("\(templatePath)/\(entry)","\(path)/\(entry)"))
            }
            
            // now we do
            for entry in allInclusiveEntries {
                createAuthoredCodeFile(srcPath: entry.0, destPath: entry.1)
            }
        } catch {
            print(error)
        }
    }
    
    static var shared: AppCodeTemplate = AppCodeTemplate()
}
