//
//  FileList+Structure.swift
//  LindDE
//
//  Created by lindsey on 05.05.25.
//

import Foundation
import SwiftUI

struct FileListEntry: Identifiable {
    enum FileListEntryType {
        case file
        case dir
    }
    
    let id: UUID = UUID()
    let name: String
    let path: String
    let isLink: Bool
    let type: FileListEntryType
    
    static func getEntry(ofPath path: String) -> FileListEntry {
        var entry = FileListEntry(name: "N/A", path: path, isLink: false, type: .file)
        var path = path
        do {
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
            if exists {
                let attributes = try FileManager.default.attributesOfItem(atPath: path)
                if let fileType = attributes[.type] as? FileAttributeType {
                    let isLink: Bool = (fileType == .typeSymbolicLink) ? true : false
                    if isLink { path = try FileManager.default.destinationOfSymbolicLink(atPath: path) }
                    
                    entry = FileListEntry(name: URL(fileURLWithPath: path).lastPathComponent,
                                                 path: path,
                                                 isLink: isLink,
                                                 type: isDirectory.boolValue ? .dir : .file)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        
        return entry
    }
    
    static func getEntries(ofPath path: String) -> [FileListEntry] {
        var entries: [FileListEntry] = []
        
        do {
            let rawEntries: [String] = try FileManager.default.contentsOfDirectory(atPath: path)
            for rawEntry in rawEntries { entries.append(FileListEntry.getEntry(ofPath: "\(path)/\(rawEntry)")) }
        } catch {
            print(error)
        }
        
        entries.sort {
            if $0.type == $1.type {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return $0.type == .dir
        }
        
        return entries
    }
    
    static func getEntries(ofPath path: String, perEntryHandler: (FileListEntry) -> Void) {
        var entries: [FileListEntry] = []
        
        do {
            let rawEntries: [String] = try FileManager.default.contentsOfDirectory(atPath: path)
            for rawEntry in rawEntries { entries.append(FileListEntry.getEntry(ofPath: "\(path)/\(rawEntry)")) }
        } catch {
            print(error)
        }
        
        entries.sort {
            if $0.type == $1.type {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return $0.type == .dir
        }
        
        for item in entries {
            perEntryHandler(item)
        }
    }
}

class FileAction: ObservableObject {
    enum FileActionType {
        case none
        case move
        case copy
    }
    
    @Published var path: String = ""
    @Published var action: FileAction.FileActionType = .none
    
    static let shared = FileAction()
}
