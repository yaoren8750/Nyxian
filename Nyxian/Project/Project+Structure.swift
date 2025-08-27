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

/*
Project Structure:

{UUID}/
 ├── Config/
 │   ├── Project.plist      // Holds some information relevant for the AppProject structure
 │   ├── Editor.plist   // Holds some information of the code editor configuration this project has.. necessary for contribution so people dont write all with their own code editor settings which causes massive mess
 │   ├── SubTargets.plist   // Holds some information of sub projects in that project (such as static libraries, frameworks and more)
 │   └── Flags.plist        // Holds some information of compiler and linker flags
 ├── Resources/
 ├── main.m                 // Entry point of the iOS application
 ├── viewcontroller.m       // UIKit view controller of the iOS application
 └── appdelegate.m          // UIKit app delegation of the iOS application
*/

/*class ProjectConfig: NXPlistHelper {
    enum ProjectType: Int {
        case App = 1
        case Binary = 2
    }
    
    var executable: String { self.readString(forKey: "LDEExecutable", withDefaultValue: "Unknown") }
    var displayname: String { self.readString(forKey: "LDEDisplayName", withDefaultValue: self.executable) }
    var bundleid: String { self.readString(forKey: "LDEBundleIdentifier", withDefaultValue: "com.unknown.fallback.id") }
    var minimum_version: String { self.readString(forKey: "LDEMinimumVersion", withDefaultValue: UIDevice.current.systemVersion) }
    var version: String { self.readString(forKey: "LDEBundleVersion", withDefaultValue: "1.0") }
    var shortVersion: String { self.readString(forKey: "LDEBundleShortVersion", withDefaultValue: "1.0") }
    var platformTriple: String { self.readString(forKey: "LDEOverwriteTriple", withDefaultValue: "apple-arm64-ios\(self.minimum_version)") }
    var infoDictionary: [String:Any] { self.readSecure(fromKey: "LDEBundleInfo", withDefaultValue: [:], classType: NSClassFromString("NSMutableDictionary")) as! [String:Any] }
    var subTargets: [String] { self.readArray(forKey: "LDESubTargets", withDefaultValue: []) as! [String] }
    var projectType: Int { self.readInteger(forKey: "LDEProjectType", withDefaultValue: ProjectType.App.rawValue) }
    var compiler_flags: [String] { self.readArray(forKey: "LDECompilerFlags", withDefaultValue: []) as! [String] }
    var linker_flags: [String] { self.readArray(forKey: "LDELinkerFlags", withDefaultValue: []) as! [String] }
    
    // Overwritable variables
    var threads: Int {
        let maxThreads: Int = getOptimalThreadCount()
        var pthreads: Int = (self.readSecure(fromKey: "LDEOverwriteThreads", withDefaultValue: NSNumber(value: getCpuThreads()), classType: NSClassFromString("NSNumber")) as! NSNumber).intValue
        if pthreads == 0 {
            pthreads = getCpuThreads()
        } else if pthreads > maxThreads {
            pthreads = maxThreads
        }
        return pthreads
    }
    var increment: Bool {
        self.readKey("LDEOverwriteIncrementalBuild") as? Bool
        ?? ((UserDefaults.standard.object(forKey: "LDEIncrementalBuild") != nil)
            ? UserDefaults.standard.bool(forKey: "LDEIncrementalBuild")
            : true)
    }
    var restartApp: Bool {
        self.readKey("LDEOverwriteReopen") as? Bool
        ?? ((UserDefaults.standard.object(forKey: "LDEReopen") != nil)
            ? UserDefaults.standard.bool(forKey: "LDEReopen")
            : false)
    }
    var restartAppOnSucceed: Bool {
        self.readKey("LDEOverwriteReopenSucceed") as? Bool
        ?? ((UserDefaults.standard.object(forKey: "LDEReopenSucceed") != nil)
            ? UserDefaults.standard.bool(forKey: "LDEReopenSucceed")
            : true)
    }
    
    func getCompilerFlags() -> [String] {
        var flags: [String] = self.compiler_flags
        flags.append("-target")
        flags.append(self.platformTriple)
        return flags
    }
}

class CodeEditorConfig: NXPlistHelper {
    var showLine: Bool { self.readBoolean(forKey: "LDEShowLines", withDefaultValue: true) }
    var showSpaces: Bool { self.readBoolean(forKey: "LDEShowSpace", withDefaultValue: true) }
    var showReturn: Bool { self.readBoolean(forKey: "LDEShowReturn", withDefaultValue: true) }
    var wrapLine: Bool { self.readBoolean(forKey: "LDEWrapLine", withDefaultValue: true) }
    var fontSize: Double { self.readDouble(forKey: "LDEFontSize", withDefaultValue: 10.0) }
}*/

class AppProject: Identifiable {
    let id: UUID = UUID()

    private(set) var projectTableCell: ProjectTableCell!
    let projectConfig: NXProjectConfig
    let codeEditorConfig: NXCodeEditorConfig
    
    private let path: String
    private let cachePath: String
    
    init(path: String) {
        // store the path
        self.path = path
        self.cachePath = Bootstrap.shared.bootstrapPath("/Cache/\(self.path.URLGet().lastPathComponent)")
        
        // validate if the project plist exists and extract information
        self.projectConfig = NXProjectConfig(plistPath: "\(self.path)/Config/Project.plist")
        self.codeEditorConfig = NXCodeEditorConfig(plistPath: "\(self.path)/Config/Editor.plist")
        self.projectTableCell = ProjectTableCell(project: self)
    }
    
    static func createAppProject(atPath path: String,
                                 executable: String,
                                 bundleid: String,
                                 mode: NXProjectType) -> AppProject {
        
        // first we prepare all information we need
        let path: String = "\(path)/\(UUID())"
        
        let projectdict: [String: Any] = [
            "LDEExecutable": executable,
            "LDEDisplayName": executable,
            "LDEBundleIdentifier": bundleid,
            "LDEMinimumVersion": UIDevice.current.systemVersion,
            "LDECompilerFlags": ["-fobjc-arc"],
            "LDELinkerFlags": ["-ObjC", "-lc", "-lc++", "-framework", "Foundation", "-framework", "UIKit"],
            "LDEBundleInfo": [:],
            "LDESubTargets": [],
            "LDEProjectType": mode.rawValue,
            "LDEBundleVersion": "1.0",
            "LDEBundleShortVersion": "1.0"
        ]
        
        let editordict: [String: Any] = [
            "LDEShowLines": true,
            "LDEShowSpace": true,
            "LDEShowReturn": true,
            "LDEWrapLine": true,
            "LDEFontSize": 10.0
        ]
        
        // now we create the project
        do {
            // creating project structure
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(atPath: "\(path)/Config", withIntermediateDirectories: true)
            try FileManager.default.createDirectory(atPath: "\(path)/Resources", withIntermediateDirectories: true)
            
            // writing plist data
            func writeDict(usingDict dict: [String:Any],
                           toPath path: String) throws {
                let plistData = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
                try plistData.write(to: URL(fileURLWithPath: path))
            }
            
            try writeDict(usingDict: projectdict, toPath: "\(path)/Config/Project.plist")
            try writeDict(usingDict: editordict, toPath: "\(path)/Config/Editor.plist")
            
            // MARK: For testing
            NXCodeTemplate.shared().generateCodeStructure(fromTemplateScheme: .objCApp,
                                                          withProjectName: executable,
                                                          intoPath: path)
        } catch {
            print(error.localizedDescription)
            NotificationServer.NotifyUser(level: .error, notification: "Failed to create project: \(error.localizedDescription)")
        }
        
        return AppProject(path: path)
    }
    
    static func listProjects(ofPath path: String) -> [AppProject] {
        var appProjects: [AppProject] = []
        
        do {
            let entries: [String] = try FileManager.default.contentsOfDirectory(atPath: path)
            
            for entry in entries {
                appProjects.append(AppProject(path: "\(path)/\(entry)"))
            }
        } catch {
            print(error)
        }
        
        return appProjects
    }
    
    static func removeProject(project: AppProject) {
        try? FileManager.default.removeItem(atPath: project.getCachePath())
        try? FileManager.default.removeItem(atPath: project.path)
    }
    
    ///
    /// Subpath variable functions
    ///
    func getPath() -> String {
        return path
    }
    
    func getUUID() -> String {
        return URL(fileURLWithPath: self.path).lastPathComponent
    }
    
    func getCachePath() -> String {
        return cachePath
    }
    
    func getResourcesPath() -> String {
        return "\(path)/Resources"
    }
    
    func getPayloadPath() -> String {
        return "\(cachePath)/Payload"
    }
    
    func getBundlePath() -> String {
        return "\(cachePath)/Payload/\(projectConfig.executable!).app"
    }
    
    func getMachOPath() -> String {
        if self.projectConfig.type.int32Value == NXProjectType.app.rawValue ||
            self.projectConfig.type.int32Value == NXProjectType.binary.rawValue {
            return "\(cachePath)/Payload/\(projectConfig.executable!).app/\(projectConfig.executable!)"
        } else {
            return "\(cachePath)/\(projectConfig.executable!)"
        }
    }
    
    func getPackagePath() -> String {
        return "\(cachePath)/\(projectConfig.executable!).ipa"
    }
    
    func getHomePath() -> String {
        return "\(cachePath)/data"
    }
    
    func getTmpPath() -> String {
        return "\(cachePath)/data/tmp"
    }
    
    ///
    /// Public
    ///
    
    @discardableResult func reload() -> Bool {
        let needsUIReload: Bool = self.projectConfig.reloadIfNeeded()
        if needsUIReload {
            self.projectTableCell.reload()
        }
        return needsUIReload
    }
}
