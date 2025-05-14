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
    var plistHelper: PlistHelper?
    
    var executable: String = "Unknown"
    var displayname: String = "Unknown"
    var bundleid: String = "com.unknown.fallback.app"
    var minimum_version: String = "16.5"
    
    var compiler_flags: [String] = []
    var linker_flags: [String] = []
    
    init(
        executable: String,
        displayname: String,
        bundleid: String,
        minimum_version: String,
        compiler_flags: [String],
        linker_flags: [String]
    ) {
        self.executable = executable
        self.displayname = displayname
        self.bundleid = bundleid
        self.minimum_version = minimum_version
        self.compiler_flags = compiler_flags
        self.linker_flags = linker_flags
    }
    
    init(withPath plistPath: String) {
        self.plistHelper = PlistHelper(plistPath: plistPath)
        
        self.plistHelper?.onReload = { [weak self] dict in
            self?.executable = (dict["LDEExecutable"] as? String) ?? "Unknown"
            self?.displayname = (dict["LDEDisplayName"] as? String) ?? "Unknown"
            self?.bundleid = (dict["LDEBundleIdentifier"] as? String) ?? "com.unknown.fallback.app"
            self?.minimum_version = (dict["LDEMinimumVersion"] as? String) ?? "16.5"
            self?.compiler_flags = (dict["LDECompilerFlags"] as? [String]) ?? []
            self?.linker_flags = (dict["LDELinkerFlags"] as? [String]) ?? []
        }
        
        let dict: [String:Any] = (NSDictionary(contentsOfFile: plistPath) as? [String:Any]) ?? [:]
        
        self.plistHelper?.onReload(dict)
    }
}

class CodeEditorConfig {
    var plistHelper: PlistHelper?
    
    var showLine: Bool = true
    var showSpaces: Bool = true
    var showReturn: Bool = true
    var wrapLine: Bool = true
    var fontSize: Double = 0.0
    
    init() {
        
    }
    
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

struct AppProject: Identifiable {
    let id: UUID = UUID()

    let projectConfig: ProjectConfig
    let codeEditorConfig: CodeEditorConfig
    
    private let path: String
    
    init(path: String) {
        // store the path
        self.path = path
        
        // validate if the project plist exists and extract information
        self.projectConfig = ProjectConfig(withPath: "\(self.path)/Config/Project.plist")
        self.codeEditorConfig = CodeEditorConfig(withPath: "\(self.path)/Config/Editor.plist")
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
            "LDEMinimumVersion": getPlatformTriple(),
            "LDECompilerFlags": ["-fobjc-arc"],
            "LDELinkerFlags": ["-ObjC", "-lc", "-lc++", "-framework", "Foundation", "-framework", "UIKit"]
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
                } catch {}
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
        let cache: (Bool,String) = project.getCachePath()
        try? FileManager.default.removeItem(atPath: project.path)
        if cache.0 {
            try? FileManager.default.removeItem(atPath: cache.1)
        }
    }
    
    ///
    /// Subpath variable functions
    ///
    func getPath() -> String {
        return path
    }
    
    func getCachePath() -> (Bool,String) {
        let uuidUsedInGeneration: String = self.path.URLGet().lastPathComponent
        
        return getValidationPath("\(Bootstrap.shared.bootstrapPath("/Cache/\(uuidUsedInGeneration)"))")
    }
    
    func getResourcesPath() -> (Bool,String) {
        return getValidationPath("\(path)/Resources")
    }
    
    func getPayloadPath() -> (Bool,String) {
        return getValidationPath("\(path)/Payload")
    }
    
    func getBundlePath() -> (Bool,String) {
        return getValidationPath("\(path)/Payload/\(projectConfig.executable).app")
    }
    
    func getMachOPath() -> (Bool,String) {
        return getValidationPath("\(path)/Payload/\(projectConfig.executable).app/\(projectConfig.executable)")
    }
    
    func getPackagePath() -> (Bool,String) {
        return getValidationPath("\(path)/\(projectConfig.executable).ipa")
    }
    
    ///
    /// Private
    ///
    private func getValidationPath(_ path: String) -> (Bool,String) {
        if FileManager.default.fileExists(atPath: path) {
            return (true,path)
        }
        return (false,path)
    }
}
