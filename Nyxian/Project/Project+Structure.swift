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
    
    var plistHelper: PlistHelper?
    
    var executable: String = "Unknown"
    var displayname: String = "Unknown"
    var bundleid: String = "com.unknown.fallback.app"
    var minimum_version: String = "16.5"
    var version: String = "1.0"
    var shortVersion: String = "1.0"
    
    var infoDictionary: [String:Any] = [:]
    var subTargets: [String] = []
    var projectType: Int = ProjectType.App.rawValue
    var compiler_flags: [String] = []
    var linker_flags: [String] = []
    
    // Overwritable variables
    var threads: Int = 1
    var increment: Bool = false
    var restartApp: Bool = false
    
    init(withPath plistPath: String) {
        self.plistHelper = PlistHelper(plistPath: plistPath)
        
        self.plistHelper?.onReload = { [weak self] dict in
            self?.executable = (dict["LDEExecutable"] as? String) ?? "Unknown"
            self?.displayname = (dict["LDEDisplayName"] as? String) ?? (self?.executable ?? "Unknown")
            self?.bundleid = (dict["LDEBundleIdentifier"] as? String) ?? "com.unknown.fallback.app"
            self?.minimum_version = (dict["LDEMinimumVersion"] as? String) ?? "16.5"
            self?.compiler_flags = (dict["LDECompilerFlags"] as? [String]) ?? []
            self?.linker_flags = (dict["LDELinkerFlags"] as? [String]) ?? []
            self?.version = (dict["LDEBundleVersion"] as? String) ?? "1.0"
            self?.shortVersion = (dict["LDEBundleShortVersion"] as? String) ?? "1.0"
            self?.subTargets = (dict["LDESubTargets"] as? [String]) ?? []
            
            let maxThreads: Int = getOptimalThreadCount()
            self?.threads = (dict["LDEOverwriteThreads"] as? Int) ?? 0
            if (self?.threads ?? 0) == 0 {
                self?.threads = getCpuThreads()
            } else if (self?.threads ?? 0) > maxThreads {
                self?.threads = maxThreads
            }
            
            self?.increment = (dict["LDEOverwriteIncrementalBuild"] as? Bool)
                ?? ((UserDefaults.standard.object(forKey: "LDEIncrementalBuild") != nil)
                    ? UserDefaults.standard.bool(forKey: "LDEIncrementalBuild")
                    : true)

            self?.restartApp = (dict["LDEOverwriteReopen"] as? Bool)
                ?? ((UserDefaults.standard.object(forKey: "LDEReopen") != nil)
                    ? UserDefaults.standard.bool(forKey: "LDEReopen")
                    : false)
            
            self?.infoDictionary = (dict["LDEBundleInfo"] as? [String:Any]) ?? [:]
            self?.projectType = (dict["LDEProjectType"] as? Int) ?? ProjectType.App.rawValue
        }
        
        let dict: [String:Any] = (NSDictionary(contentsOfFile: plistPath) as? [String:Any]) ?? [:]
        
        self.plistHelper?.onReload(dict)
    }
    
    func getCompilerFlags() -> [String] {
        var flags: [String] = self.compiler_flags
        flags.append("-target")
        flags.append("arm64-apple-ios\(self.minimum_version)")
        return flags
    }
}

class CodeEditorConfig {
    var plistHelper: PlistHelper?
    
    var showLine: Bool = true
    var showSpaces: Bool = true
    var showReturn: Bool = true
    var wrapLine: Bool = true
    var fontSize: Double = 0.0
    
    init() {}
    
    init(
        showLine: Bool,
        showSpaces: Bool,
        showReturn: Bool,
        wrapLine: Bool,
        fontSize: Double
    ) {
        self.showLine = showLine
        self.showSpaces = showSpaces
        self.showReturn = showReturn
        self.wrapLine = wrapLine
        self.fontSize = 10.0
    }
    
    static var shared: CodeEditorConfig = CodeEditorConfig(
        showLine: true,
        showSpaces: true,
        showReturn: true,
        wrapLine: true,
        fontSize: 10.0
    )
    
    init(withPath plistPath: String) {
        self.plistHelper = PlistHelper(plistPath: plistPath)
        
        self.plistHelper?.onReload = { [weak self] dict in
            self?.showLine = (dict["LDEShowLines"] as? Bool) ?? true
            self?.showSpaces = (dict["LDEShowSpace"] as? Bool) ?? true
            self?.showReturn = (dict["LDEShowReturn"] as? Bool) ?? true
            self?.wrapLine = (dict["LDEWrapLine"] as? Bool) ?? true
            self?.fontSize = (dict["LDEFontSize"] as? Double) ?? 10.0
        }
        
        let dict: [String:Any] = (NSDictionary(contentsOfFile: plistPath) as? [String:Any]) ?? [:]
        
        self.plistHelper?.onReload(dict)
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
    func writeBack() {
        self.projectConfig.plistHelper?.overWritePlist(dict: [
            "LDEExecutable": self.projectConfig.executable,
            "LDEDisplayName": self.projectConfig.displayname,
            "LDEBundleIdentifier": self.projectConfig.bundleid,
            "LDEMinimumVersion": self.projectConfig.minimum_version,
            "LDECompilerFlags": self.projectConfig.compiler_flags,
            "LDELinkerFlags": self.projectConfig.linker_flags
        ])
        
        self.codeEditorConfig.plistHelper?.overWritePlist(dict: [
            "LDEShowLines": self.codeEditorConfig.showLine,
            "LDEShowSpace": self.codeEditorConfig.showSpaces,
            "LDEShowReturn": self.codeEditorConfig.showReturn,
            "LDEWrapLine": self.codeEditorConfig.wrapLine,
            "LDEFontSize": self.codeEditorConfig.fontSize
        ])
    }
    
    @discardableResult func reload() -> Bool {
        let needsUIReload: Bool = self.projectConfig.plistHelper?.reloadIfNeeded() ?? false
        if needsUIReload {
            self.projectTableCell.reload()
        }
        return needsUIReload
    }
}
