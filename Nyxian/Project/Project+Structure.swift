//
//  Project.swift
//  LindDE
//
//  Created by lindsey on 05.05.25.
//

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

class ProjectConfig {
    enum ProjectType: Int {
        case App = 1
        case Staticlib = 2
        case Dylib = 3
    }
    
    var plistHelper: PlistHelper
    
    var executable: String { (plistHelper.dictionary?["LDEExecutable"] as? String) ?? "Unknown" }
    var displayname: String { (plistHelper.dictionary?["LDEDisplayName"] as? String) ?? self.executable }
    var bundleid: String { (plistHelper.dictionary?["LDEBundleIdentifier"] as? String) ?? "com.unknown.fallback.app" }
    var minimum_version: String { (plistHelper.dictionary?["LDEMinimumVersion"] as? String) ?? UIDevice.current.systemVersion }
    var version: String { (plistHelper.dictionary?["LDEBundleVersion"] as? String) ?? "1.0" }
    var shortVersion: String { (plistHelper.dictionary?["LDEBundleShortVersion"] as? String) ?? "1.0" }
    var platformTriple: String { (plistHelper.dictionary?["LDEOverwriteTriple"] as? String) ?? "apple-arm64-ios\(self.minimum_version)" }
    
    var infoDictionary: [String:Any] { (plistHelper.dictionary?["LDEBundleInfo"] as? [String:Any]) ?? [:] }
    var subTargets: [String] { (plistHelper.dictionary?["LDESubTargets"] as? [String]) ?? [] }
    var projectType: Int { (plistHelper.dictionary?["LDEProjectType"] as? Int) ?? ProjectType.App.rawValue }
    var compiler_flags: [String] { (plistHelper.dictionary?["LDECompilerFlags"] as? [String]) ?? [] }
    var linker_flags: [String] { (plistHelper.dictionary?["LDELinkerFlags"] as? [String]) ?? [] }
    
    // Overwritable variables
    var threads: Int {
        let maxThreads: Int = getOptimalThreadCount()
        var pthreads: Int = (plistHelper.dictionary?["LDEOverwriteThreads"] as? Int) ?? 0
        if pthreads == 0 {
            pthreads = getCpuThreads()
        } else if pthreads > maxThreads {
            pthreads = maxThreads
        }
        return pthreads
    }
    var increment: Bool {
        (plistHelper.dictionary?["LDEOverwriteIncrementalBuild"] as? Bool)
        ?? ((UserDefaults.standard.object(forKey: "LDEIncrementalBuild") != nil)
            ? UserDefaults.standard.bool(forKey: "LDEIncrementalBuild")
            : true)
    }
    var restartApp: Bool {
        (plistHelper.dictionary?["LDEOverwriteReopen"] as? Bool)
        ?? ((UserDefaults.standard.object(forKey: "LDEReopen") != nil)
            ? UserDefaults.standard.bool(forKey: "LDEReopen")
            : false)
    }
    var restartAppOnSucceed: Bool {
        (plistHelper.dictionary?["LDEOverwriteReopenSucceed"] as? Bool)
        ?? ((UserDefaults.standard.object(forKey: "LDEReopenSucceed") != nil)
            ? UserDefaults.standard.bool(forKey: "LDEReopenSucceed")
            : true)
    }
    
    init(withPath plistPath: String) {
        self.plistHelper = PlistHelper(plistPath: plistPath)
    }
    
    func getCompilerFlags() -> [String] {
        var flags: [String] = self.compiler_flags
        flags.append("-target")
        flags.append(self.platformTriple)
        return flags
    }
}

class CodeEditorConfig {
    var plistHelper: PlistHelper
    
    var showLine: Bool { (plistHelper.dictionary?["LDEShowLines"] as? Bool) ?? true }
    var showSpaces: Bool { (plistHelper.dictionary?["LDEShowSpace"] as? Bool) ?? true }
    var showReturn: Bool { (plistHelper.dictionary?["LDEShowReturn"] as? Bool) ?? true }
    var wrapLine: Bool { (plistHelper.dictionary?["LDEWrapLine"] as? Bool) ?? true }
    var fontSize: Double { (plistHelper.dictionary?["LDEFontSize"] as? Double) ?? 10.0 }
    
    init(withPath plistPath: String) {
        self.plistHelper = PlistHelper(plistPath: plistPath)
    }
}

class AppProject: Identifiable {
    let id: UUID = UUID()

    private(set) var projectTableCell: ProjectTableCell!
    let projectConfig: ProjectConfig
    let codeEditorConfig: CodeEditorConfig
    
    private let path: String
    private let cachePath: String
    
    init(path: String) {
        // store the path
        self.path = path
        self.cachePath = Bootstrap.shared.bootstrapPath("/Cache/\(self.path.URLGet().lastPathComponent)")
        
        // validate if the project plist exists and extract information
        self.projectConfig = ProjectConfig(withPath: "\(self.path)/Config/Project.plist")
        self.codeEditorConfig = CodeEditorConfig(withPath: "\(self.path)/Config/Editor.plist")
        self.projectTableCell = ProjectTableCell(project: self)
    }
    
    static func createAppProject(atPath path: String,
                                 executable: String,
                                 bundleid: String) -> AppProject {
        
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
            "LDEProjectType": ProjectConfig.ProjectType.App.rawValue,
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
                           toPath path: String) {
                
                do {
                    var plistData = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
                    try plistData.write(to: URL(fileURLWithPath: path))
                } catch {
                    print(error.localizedDescription)
                    NotificationServer.NotifyUser(level: .error, notification: "Failed to create project: \(error.localizedDescription)")
                }
            }
            
            writeDict(usingDict: projectdict, toPath: "\(path)/Config/Project.plist")
            writeDict(usingDict: editordict, toPath: "\(path)/Config/Editor.plist")
            
            AppCodeTemplate.shared.createCode(
                withProjectName: executable,
                atPath: path,
                withScheme: .objc
            )
        } catch {
            print(error)
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
        return "\(cachePath)/Payload/\(projectConfig.executable).app"
    }
    
    func getMachOPath() -> String {
        if self.projectConfig.projectType == ProjectConfig.ProjectType.App.rawValue {
            return "\(cachePath)/Payload/\(projectConfig.executable).app/\(projectConfig.executable)"
        } else {
            return "\(cachePath)/\(projectConfig.executable)"
        }
    }
    
    func getPackagePath() -> String {
        return "\(cachePath)/\(projectConfig.executable).ipa"
    }
    
    ///
    /// Public
    ///
    
    @discardableResult func reload() -> Bool {
        let needsUIReload: Bool = self.projectConfig.plistHelper.reloadIfNeeded()
        if needsUIReload {
            self.projectTableCell.reload()
        }
        return needsUIReload
    }
}
