//
//  Project+Template.swift
//  LindDE
//
//  Created by fridakitten on 06.05.25.
//

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
