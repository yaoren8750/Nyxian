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
