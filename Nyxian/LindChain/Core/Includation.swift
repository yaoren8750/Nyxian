//
//  Includation.swift
//  LindDE
//
//  Created by fridakitten on 09.05.25.
//

import Foundation

class HeaderIncludationsGatherer {
    let path: String
    var includes: [String]
    
    init(path: String) {
        self.path = path
        self.includes = []

        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            try gatherIncludations(forFile: path, content: content)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func matchIncludations(content: String) throws -> [String] {
        let regex = try NSRegularExpression(pattern: #"#(?:import|include)\s+"([^"]+)""#, options: [])
        let matches = regex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
        let includePaths = matches.compactMap { match -> String? in
            guard let range = Range(match.range(at: 1), in: content) else { return nil }
            return String(content[range])
        }
        return includePaths
    }
    
    func gatherIncludations(forFile filePath: String, content: String) throws {
        let items = try matchIncludations(content: content)
        
        for item in items {
            let resolvedPath = resolveFilePath(forInclude: item, fromFile: filePath)
            
            includes.append(resolvedPath)
            
            if FileManager.default.fileExists(atPath: resolvedPath) {
                do {
                    let includedContent = try String(contentsOfFile: resolvedPath, encoding: .utf8)
                    try gatherIncludations(forFile: resolvedPath, content: includedContent)
                } catch {
                    print("Error reading file \(resolvedPath): \(error.localizedDescription)")
                }
            }
        }
    }
    
    func resolveFilePath(forInclude include: String, fromFile filePath: String) -> String {
        let directory = (filePath as NSString).deletingLastPathComponent
        return (directory as NSString).appendingPathComponent(include)
    }
}
