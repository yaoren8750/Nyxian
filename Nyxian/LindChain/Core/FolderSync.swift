//
//  FolderSync.swift
//  LindDE
//
//  Created by fridakitten on 09.05.25.
//

import Foundation

func expectedObjectFile(forPath path: String) -> String {
    let url = URL(fileURLWithPath: "/\(path)").deletingPathExtension().appendingPathExtension("o")
    return String(String(url.path).dropFirst())
}

func relativePath(from base: URL, to fullPath: URL) -> String {
    let baseComponents = base.standardized.pathComponents
    let fullComponents = fullPath.standardized.pathComponents

    let relativeComponents = Array(fullComponents.dropFirst(baseComponents.count))
    
    return relativeComponents.joined(separator: "/")
}

func syncFolderStructure(from sourceURL: URL,
                         to destinationURL: URL) throws {
    let fileManager = FileManager.default

    // Get all directories in source path
    let sourceDirectories = try fileManager.subpathsOfDirectory(atPath: sourceURL.path)
        .map { sourceURL.appendingPathComponent($0) }
        .filter { url in
            var isDir: ObjCBool = false
            return fileManager.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
        }

    // Create missing directories in destination
    for sourceDir in sourceDirectories {
        let relativePath = sourceDir.path.replacingOccurrences(of: sourceURL.path, with: "")
        let destDir = destinationURL.appendingPathComponent(relativePath)
        if !fileManager.fileExists(atPath: destDir.path) {
            try fileManager.createDirectory(at: destDir, withIntermediateDirectories: true, attributes: nil)
        }
    }

    // Get all directories in destination path
    let destinationDirectories = try fileManager.subpathsOfDirectory(atPath: destinationURL.path)
        .map { destinationURL.appendingPathComponent($0) }
        .filter { url in
            var isDir: ObjCBool = false
            return fileManager.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
        }

    // Remove extra directories in destination that don't exist in source
    for destDir in destinationDirectories {
        let relativePath = destDir.path.replacingOccurrences(of: destinationURL.path, with: "")
        let sourceDir = sourceURL.appendingPathComponent(relativePath)
        if !fileManager.fileExists(atPath: sourceDir.path) {
            try fileManager.removeItem(at: destDir)
        }
    }
    
    ///
    /// This is a early code of fixing the issue where object and source files are out of sync when removing source code files
    ///
    let rsourceSet: Set<String> = Set(FindFilesStack(
        sourceURL.path,
        ["c", "cpp", "mm", "m"],
        ["Resources"]
    ).map {
        expectedObjectFile(forPath: relativePath(from: sourceURL, to: URL(fileURLWithPath: $0)))
    })
    
    let robject: [String] = FindFilesStack(
        destinationURL.path,
        ["o"],
        ["Resources"]
    ).map {
        relativePath(from: destinationURL, to: URL(fileURLWithPath: $0))
    }
    
    for item in robject {
        if !rsourceSet.contains(item) {
            try? FileManager.default.removeItem(at: destinationURL.appendingPathComponent(item))
        }
    }
}
