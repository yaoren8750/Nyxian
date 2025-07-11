/*
 Copyright (C) 2025 SeanIsTethered
 Copyright (C) 2025 Lindsey

 This file is part of Nyxian.

 FridaCodeManager is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 FridaCodeManager is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

import UIKit
import Foundation

class Builder {
    private let project: AppProject
    private let compiler: Compiler
    private let argsString: String
    
    private var dirtySourceFiles: [String] = []
    
    let database: DebugDatabase
    
    init(project: AppProject) {
        self.project = project
        self.project.reload()
        
        self.database = DebugDatabase.getDatabase(ofPath: "\(self.project.getCachePath())/debug.json")
        self.database.reuseDatabase()
        
        var genericCompilerFlags: [String] = [
            "-isysroot",
            Bootstrap.shared.bootstrapPath("/SDK/iPhoneOS16.5.sdk"),
            "-I\(Bootstrap.shared.bootstrapPath("/Include/include"))"
        ]
        
        let compilerFlags: [String] = self.project.projectConfig.getCompilerFlags()
        genericCompilerFlags.append(contentsOf: compilerFlags)
        
        self.compiler = Compiler(genericCompilerFlags)
        
        let cachePath = project.getCachePath()
        
        try? syncFolderStructure(from: project.getPath().URLGet(), to: cachePath.URLGet())
        
        self.dirtySourceFiles = FindFilesStack(self.project.getPath(), ["c","cpp","m","mm"], ["Resources"])
        
        // Check if args have changed
        self.argsString = compilerFlags.joined(separator: " ")
        var fileArgsString: String = ""
        if FileManager.default.fileExists(atPath: "\(cachePath)/args.txt") {
            // Check if the args string matches up
            fileArgsString = (try? String(contentsOf: URL(fileURLWithPath: "\(cachePath)/args.txt"), encoding: .utf8)) ?? ""
        }
        
        if(fileArgsString == self.argsString), self.project.projectConfig.increment {
            self.dirtySourceFiles = self.dirtySourceFiles.filter { self.isFileDirty($0) }
        }
    }
    
    ///
    /// Function to detect if a file is dirty (has to be recompiled)
    ///
    private func isFileDirty(_ item: String) -> Bool {
        let objectFilePath = "\(self.project.getCachePath())/\(expectedObjectFile(forPath: relativePath(from: self.project.getPath().URLGet(), to: item.URLGet())))"
        
        // Checking if the source file is newer than the compiled object file
        guard let sourceDate = try? FileManager.default.attributesOfItem(atPath: item)[.modificationDate] as? Date,
              let objectDate = try? FileManager.default.attributesOfItem(atPath: objectFilePath)[.modificationDate] as? Date,
              objectDate > sourceDate else {
            return true
        }
        
        // Checking if the header files included by the source code are newer than the object file
        for header in HeaderIncludationsGatherer(path: item).includes {
            guard FileManager.default.fileExists(atPath: header),
                  let headerDate = try? FileManager.default.attributesOfItem(atPath: header)[.modificationDate] as? Date,
                  objectDate > headerDate else {
                return true
            }
        }
        
        return false
    }
    
    ///
    /// Function to cleanup the project from old build files
    ///
    func clean() throws {
        // now remove what was find
        for file in FindFilesStack(
            self.project.getPath(),
            ["o","tmp"],
            ["Resources","Config"]
        ) {
            try? FileManager.default.removeItem(atPath: file)
        }
        
        // if payload exists remove it
        if self.project.projectConfig.projectType == ProjectConfig.ProjectType.App.rawValue {
            let payloadPath: String = self.project.getPayloadPath()
            if FileManager.default.fileExists(atPath: payloadPath) {
                try? FileManager.default.removeItem(atPath: payloadPath)
            }
        }
    }
    
    func prepare() throws {
        if project.projectConfig.projectType != ProjectConfig.ProjectType.Dylib.rawValue {
            let bundlePath: String = self.project.getBundlePath()
            
            try FileManager.default.createDirectory(atPath: bundlePath, withIntermediateDirectories: true)
            
            // Now copy info dictionary given info dictionary and add/overwrite info
            var infoPlistData: [String:Any] = self.project.projectConfig.infoDictionary
            infoPlistData["CFBundleExecutable"] = self.project.projectConfig.executable
            infoPlistData["CFBundleIdentifier"] = self.project.projectConfig.bundleid
            infoPlistData["CFBundleName"] = self.project.projectConfig.displayname
            infoPlistData["CFBundleShortVersionString"] = self.project.projectConfig.version
            infoPlistData["CFBundleVersion"] = self.project.projectConfig.shortVersion
            infoPlistData["MinimumOSVersion"] = self.project.projectConfig.minimum_version
            infoPlistData["UIDeviceFamily"] = [1,2]
            
            let infoPlistDataSerialized = try PropertyListSerialization.data(fromPropertyList: infoPlistData, format: .xml, options: 0)
            FileManager.default.createFile(atPath:"\(bundlePath)/Info.plist", contents: infoPlistDataSerialized, attributes: nil)
        }
    }
    
    ///
    /// Function to build object files
    ///
    func compile() throws {
        let pstep: Double = 1.00 / Double(self.dirtySourceFiles.count)
        let group: DispatchGroup = DispatchGroup()
        let threader = ThreadDispatchLimiter(threads: self.project.projectConfig.threads)
        
        // Now compile
        for _ in self.dirtySourceFiles {
            group.enter()
        }
        
        for filePath in self.dirtySourceFiles {
            threader.spawn {
                let outputFilePath = "\(self.project.getCachePath())/\(expectedObjectFile(forPath: relativePath(from: self.project.getPath().URLGet(), to: filePath.URLGet())))"
                
                var issues: NSMutableArray? = NSMutableArray()
                
                if self.compiler.compileObject(
                    filePath,
                    outputFile: outputFilePath,
                    platformTriple: self.project.projectConfig.platformTriple,
                    issues: &issues
                ) != 0 {
                    threader.lockdown()
                }
                
                if let nsArray = issues as? [Synitem] {
                    self.database.setFileDebug(ofPath: filePath, synItems: nsArray)
                }
                
                XCodeButton.incrementProgress(progress: pstep)
            } completion: {
                group.leave()
            }
        }
        
        group.wait()
        
        if threader.isLockdown {
            self.database.addInternalMessage(message: "Failed to compile source code", severity: .Error)
            throw NSError()
        }
        
        do {
            try self.argsString.write(to: URL(fileURLWithPath: "\(project.getCachePath())/args.txt"), atomically: false, encoding: .utf8)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func link() throws {
        if UserDefaults.standard.integer(forKey: "LDELinker") == 0 {
            let ldArgs: [String] = [
                "-platform_version",
                "ios",
                project.projectConfig.minimum_version,
                "18.5",
                "-arch",
                "arm64",
                "-syslibroot",
                Bootstrap.shared.bootstrapPath("/SDK/iPhoneOS16.5.sdk"),
                "-o",
                self.project.getMachOPath()
            ] + FindFilesStack(
                project.getCachePath(),
                ["o"],
                ["Resources","Config"]
            ) + self.project.projectConfig.linker_flags
            
            let array: NSArray = ldArgs as NSArray
            if LinkMachO(array.mutableCopy() as? NSMutableArray) != 0 {
                self.database.addInternalMessage(message: "Linking object files together to a executable failed", severity: .Error)
                throw NSError()
            }
        } else {
            let ldPath: String = "\(Bundle.main.bundlePath)/Frameworks/ld.dylib"
            
            let ldArgs: [String] = [
                "-syslibroot",
                Bootstrap.shared.bootstrapPath("/SDK/iPhoneOS16.5.sdk"),
                "-o",
                self.project.getMachOPath()
            ] + FindFilesStack(
                project.getCachePath(),
                ["o"],
                ["Resources","Config"]
            ) + self.project.projectConfig.linker_flags
            
            if dyexec(
                ldPath,
                ldArgs
            ) != 0 {
                self.database.addInternalMessage(message: "Linking object files together to a executable failed", severity: .Error)
                throw NSError()
            }
        }
    }
    
    func sign() throws {
        if project.projectConfig.projectType != ProjectConfig.ProjectType.Dylib.rawValue {
            // Now we copy use it
            if !CertBlob.isReady {
                self.database.addInternalMessage(message: "Zsign server doesnt run, please re/import your apple issued developer certificate", severity: .Error)
                throw NSError()
            }
            
            let zsign = CertBlob.signer!
            
            if !zsign.sign(self.project.getBundlePath()) {
                self.database.addInternalMessage(message: "Zsign server failed to sign app bundle", severity: .Error)
                throw NSError()
            }
        }
    }
    
    func package() throws {
        if project.projectConfig.projectType != ProjectConfig.ProjectType.Dylib.rawValue {
            if FileManager.default.fileExists(atPath: self.project.getPackagePath()) {
                try FileManager.default.removeItem(atPath: self.project.getPackagePath())
            }
            
            try FileManager.default.zipItem(
                at: URL(fileURLWithPath: self.project.getPayloadPath()),
                to: URL(fileURLWithPath: self.project.getPackagePath())
            )
        }
    }
    
    func install() throws {
        if project.projectConfig.projectType != ProjectConfig.ProjectType.Dylib.rawValue {
            let installer = try Installer(
                path: self.project.getPackagePath().URLGet(),
                metadata: AppData(id: self.project.projectConfig.bundleid,
                                  version: 1, name: self.project.projectConfig.displayname),
                image: nil
            )
            
            let waitonmebaby: DispatchSemaphore = DispatchSemaphore(value: 0)
            installer.installCompletionHandler {
                waitonmebaby.signal()
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.open(installer.iTunesLink)
            }
            
            waitonmebaby.wait()
        }
    }
    
    ///
    /// Static function to build the project
    ///
    static func buildProject(withProject project: AppProject,
                             completion: @escaping (Bool) -> Void) {
        project.projectConfig.plistHelper?.reloadData()
        
        if project.projectConfig.minimum_version > UIDevice.current.systemVersion {
            NotificationServer.NotifyUser(level: .error, notification: "App cannot be build, host is too old. Version \(project.projectConfig.minimum_version) is needed to build the app!")
            completion(true)
            return
        }
        
        XCodeButton.resetProgress()
        
        pthread_dispatch {
            Bootstrap.shared.waitTillDone()
            
            var result: Bool = true
            let builder: Builder = Builder(
                project: project
            )
            
            var resetNeeded: Bool = false
            func progressStage(systemName: String? = nil, increment: Double? = nil, handler: () throws -> Void) throws {
                let doReset: Bool = (increment == nil)
                if doReset, resetNeeded {
                    XCodeButton.resetProgress()
                    resetNeeded = false
                }
                if let systemName = systemName { XCodeButton.switchImage(systemName: systemName) }
                try handler()
                if !doReset, let increment = increment {
                    XCodeButton.incrementProgress(progress: increment)
                    resetNeeded = true
                }
            }
            
            func progressFlowBuilder(flow: [(String?,Double?,() throws -> Void)]) throws {
                for item in flow { try progressStage(systemName: item.0, increment: item.1, handler: item.2) }
            }
            
            do {
                // doit
                try progressFlowBuilder(flow: [
                    (nil,nil,{ try builder.clean() }),
                    (nil,nil,{ try builder.prepare() }),
                    (nil,nil,{ try builder.compile() }),
                    ("link",0.3,{ try builder.link() }),
                    ("checkmark.seal.text.page.fill",0.3,{ try builder.sign() }),
                    ("archivebox.fill",0.4,{ try builder.package() }),
                    (nil,nil,{ try builder.clean() }),
                    ("arrow.down.app.fill",nil,{try builder.install() })
                ])
            } catch {
                try? builder.clean()
                result = false
            }
            
            builder.database.saveDatabase(toPath: "\(project.getCachePath())/debug.json")
            
            completion(result)
        }
    }
}
