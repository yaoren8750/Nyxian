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

///
/// Class to log messages
///
@objc class LDELogger: NSObject {
    static var key: String = ""
    static var log: String {
        get {
            return UserDefaults.standard.string(forKey: "LDELog.\(key)") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "LDELog.\(key)")
        }
    }
    
    @objc static var pipe: Pipe = Pipe()
    
    static func setup() {
        self.pipe.fileHandleForReading.readabilityHandler = { handle in
            let logData = handle.availableData
            if !logData.isEmpty, let logString = String(data: logData, encoding: .utf8) {
                self.log.append(logString)
            }
        }
    }
    
    static func clear() {
        log = ""
    }
    
    static func log(forProject project: NXProject) {
        self.key = project.path.URLGet().lastPathComponent
    }
    
    @objc static func getfd() -> Int32 {
        return self.pipe.fileHandleForWriting.fileDescriptor
    }
}
