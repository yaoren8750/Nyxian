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
    
    private(set) var dirtySourceFiles: [String] = []
    
    static var abortHandler: () -> Void = {}
    static var _abort: Bool = false
    static var abort: Bool {
        get {
            return _abort
        }
        set {
            _abort = newValue
            abortHandler()
        }
    }
    
    init(project: AppProject) {
        project.reload()
        
        self.project = project
        
        var genericCompilerFlags: [String] = [
            "-isysroot",
            Bootstrap.shared.bootstrapPath("/SDK/iPhoneOS16.5.sdk"),
            "-I\(Bootstrap.shared.bootstrapPath("/Include/include"))"
        ]
        
        genericCompilerFlags.append(contentsOf: self.project.projectConfig.getCompilerFlags())
        
        self.compiler = Compiler(genericCompilerFlags)
        
        let cachePath = project.getCachePath()
        if !cachePath.0 {
            try? FileManager.default.createDirectory(atPath: cachePath.1, withIntermediateDirectories: false)
        }
        
        try? syncFolderStructure(from: project.getPath().URLGet(), to: cachePath.1.URLGet())
        
        self.dirtySourceFiles = FindFilesStack(self.project.getPath(), ["c","cpp","m","mm"], ["Resources"])
        
        if self.project.projectConfig.increment {
            for item in self.dirtySourceFiles {
                if !amIDirty(item) {
                    guard let index = self.dirtySourceFiles.firstIndex(of: item) else { continue }
                    self.dirtySourceFiles.remove(at: index)
                }
            }
        }
    }
    
    ///
    /// Function to detect if a file is dirty
    ///
    private func amIDirty(_ item: String) -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: item), let date = attributes[.modificationDate] as? Date else {
            return true
        }
        
        let rpath: String = relativePath(from: self.project.getPath().URLGet(), to: item.URLGet())
        let eobject = expectedObjectFile(forPath: rpath)
        
        ///
        /// Case 2: the date of the source file is newer than the date of the object file
        ///
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: "\(self.project.getCachePath().1)/\(eobject)"), let edate = attributes[.modificationDate] as? Date else {
            return true
        }
        
        if(edate < date) {
            return true
        }
        
        ///
        /// Case 3: Header files out of date
        ///
        let headers: [String] = HeaderIncludationsGatherer(path: item).includes
        for header in headers {
            if !FileManager.default.fileExists(atPath: header) {
                return true
            }
            
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: header), let hdate = attributes[.modificationDate] as? Date else {
                return true
            }
            
            if(edate < hdate) {
                return true
            }
        }
        
        return false
    }
    
    ///
    /// Function to cleanup the project from old build files
    ///
    func clean() throws {
        // first find the files to remove
        let trashfiles: [String] = FindFilesStack(
            project.getPath(),
            ["o","tmp"],
            ["Resources","Config"]
        )
        
        // now remove what was find
        for file in trashfiles {
            try FileManager.default.removeItem(atPath: file)
        }
        
        // if payload exists remove it
        let payloadPath: (Bool,String) = self.project.getPayloadPath()
        
        if(payloadPath.0) {
            try FileManager.default.removeItem(atPath: payloadPath.1)
        }
    }
    
    func prepare() throws {
        // Create bundle path
        try FileManager.default.createDirectory(atPath: self.project.getBundlePath().1, withIntermediateDirectories: true)
        
        // Now copy info dictionary given info dictionary
        var infoPlistData: [String:Any] = self.project.projectConfig.infoDictionary
        infoPlistData["CFBundleExecutable"] = self.project.projectConfig.executable
        infoPlistData["CFBundleIdentifier"] = self.project.projectConfig.bundleid
        infoPlistData["CFBundleName"] = self.project.projectConfig.displayname
        infoPlistData["CFBundleShortVersionString"] = "1.0"
        infoPlistData["CFBundleVersion"] = "1.0"
        infoPlistData["MinimumOSVersion"] = self.project.projectConfig.minimum_version
        
        let infoPlistDataSerialized = try PropertyListSerialization.data(fromPropertyList: infoPlistData, format: .xml, options: 0)
        FileManager.default.createFile(atPath:"\(self.project.getBundlePath().1)/Info.plist", contents: infoPlistDataSerialized, attributes: nil)
        try Builder.isAbortedCheck()
    }
    
    ///
    /// Function to build object files
    ///
    func compile() throws {
        let pstep: Double = 1.00 / Double(self.dirtySourceFiles.count)
        let lock: NSLock = NSLock()
        let group: DispatchGroup = DispatchGroup()
        let threader = ThreadDispatchLimiter(threads: self.project.projectConfig.threads)
        
        // Setup abort handler
        Builder.abortHandler = {
            threader.lockdown()
        }
        
        // now compile
        for _ in self.dirtySourceFiles {
            group.enter()
        }
        
        for file in self.dirtySourceFiles {
            threader.spawn {
                if self.compiler.compileObject(file, platformTriple: self.project.projectConfig.minimum_version) != 0 {
                    threader.lockdown()
                    return
                }
                
                let rpath: String = relativePath(from: self.project.getPath().URLGet(), to: file.URLGet())
                let eobject = expectedObjectFile(forPath: rpath)
                
                let src = "\(self.project.getPath())/\(eobject)"
                let dest = "\(self.project.getCachePath().1)/\(eobject)"
                if FileManager.default.fileExists(atPath: dest) {
                    do {
                        try FileManager.default.removeItem(atPath: dest)
                    } catch {
                        threader.lockdown()
                        return
                    }
                }
                if FileManager.default.fileExists(atPath: src) {
                    do {
                        try FileManager.default.moveItem(atPath: src, toPath: dest)
                    } catch {
                        threader.lockdown()
                        return
                    }
                } else {
                    threader.lockdown()
                    return
                }
                
                lock.lock()
                XCodeButton.incrementProgress(progress: pstep)
                lock.unlock()
            } completion: {
                group.leave()
            }
        }
        
        group.wait()
        
        // Destroy handler
        Builder.abortHandler = {}
        
        if threader.isLockdown {
            throw NSError(
                domain: "",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Compiling failed!"]
            )
        }
        
        try Builder.isAbortedCheck()
    }
    
    func link() throws {
        // Path to the ld dylib
        let ldPath: String = "\(Bundle.main.bundlePath)/Frameworks/ld.dylib"
        
        // Preparing arguments for the linker
        let ldArgs: [String] = [
            "-syslibroot",
            Bootstrap.shared.bootstrapPath("/SDK/iPhoneOS16.5.sdk"),
            "-o",
            self.project.getMachOPath().1
        ] + FindFilesStack(
            project.getCachePath().1,
            ["o"],
            ["Resources","Config"]
        ) + self.project.projectConfig.linker_flags
        
        // Linkage execution
        if dyexec(
            ldPath,
            ldArgs
        ) != 0 {
            throw NSError(
                domain: "",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Linking failed!"]
            )
        }
        
        try Builder.isAbortedCheck()
    }
    
    func sign() throws {
        // Now we copy use it
        if !CertBlob.isReady {
            throw NSError(
                domain: "",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Certificate server doesnt run! Either restart app or reimport certificate!"]
            )
        }
        
        let zsign = CertBlob.signer!
        
        if !zsign.sign(self.project.getBundlePath().1) {
            throw NSError(
                domain: "",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Signature failed!"]
            )
        }
        
        try Builder.isAbortedCheck()
    }
    
    func package() throws {
        if FileManager.default.fileExists(atPath: self.project.getPackagePath().1) {
            try FileManager.default.removeItem(atPath: self.project.getPackagePath().1)
        }
        
        try FileManager.default.zipItem(
            at: URL(fileURLWithPath: self.project.getPayloadPath().1),
            to: URL(fileURLWithPath: self.project.getPackagePath().1)
        )
        
        try Builder.isAbortedCheck()
    }
    
    func install() throws {
        let installer = try Installer(
            path: self.project.getPackagePath().1.URLGet(),
            metadata: AppData(id: self.project.projectConfig.bundleid,
                              version: 1, name: self.project.projectConfig.displayname),
            image: nil
        )
        
        var invokedInstallationPopup: Bool = false
        let waitonmebaby: DispatchSemaphore = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(installer.iTunesLink) {
                UIApplication.shared.open(installer.iTunesLink, options: [:], completionHandler: { success in
                    if success {
                        invokedInstallationPopup = true
                    }
                    waitonmebaby.signal()
                })
            }
        }
        waitonmebaby.wait()
        
        if invokedInstallationPopup {
            sleep(1)
            if OpenAppAfterReinstallTrampolineSwitch(
                installer,
                self.project) {
                exit(0)
            } else {
                throw NSError(
                    domain: "",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Open failed!"]
                )
            }
        } else {
            throw NSError(
                domain: "",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Install failed!"]
            )
        }
    }
    
    static private func isAbortedCheck() throws {
        if Builder.abort {
            throw NSError(
                domain: "",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Build aborted!"]
            )
        }
    }
    
    ///
    /// Static function to build the project
    ///
    static func buildProject(withProject project: AppProject,
                             completion: @escaping (Bool) -> Void) {
        pthread_dispatch {
            Bootstrap.shared.waitTillDone()
            
            Builder.abortHandler = {}
            Builder.abort = false
            
            var result: Bool = true
            let builder: Builder = Builder(
                project: project
            )
            
            ls_nsprint("[*] LDE Builder v1.0\n")
            
            do {
                // doit
                XCodeButton.resetProgress()
                ls_nsprint("[*] cleaning\n")
                try builder.clean()
                ls_nsprint("[*] preparing\n")
                try builder.prepare()
                ls_nsprint("[*] compiling\n")
                try builder.compile()
                XCodeButton.resetProgress()
                
                XCodeButton.switchImage(systemName: "link")
                ls_nsprint("[*] linking\n")
                try builder.link()
                XCodeButton.incrementProgress(progress: 0.3)
                
                XCodeButton.switchImage(systemName: "checkmark.seal.text.page.fill")
                ls_nsprint("[*] signing\n")
                try builder.sign()
                XCodeButton.incrementProgress(progress: 0.3)
                
                XCodeButton.switchImage(systemName: "archivebox.fill")
                ls_nsprint("[*] packaging\n")
                try builder.package()
                XCodeButton.incrementProgress(progress: 0.4)
                
                ls_nsprint("[*] cleaning\n")
                try builder.clean()
                XCodeButton.resetProgress()
                
                XCodeButton.switchImage(systemName: "arrow.down.app.fill")
                ls_nsprint("[*] installing\n")
                try builder.install()
            } catch {
                if !Builder.abort {
                    result = false
                } else {
                    try? builder.clean()
                }
                ls_nsprint(error.localizedDescription)
            }
            
            completion(result)
        }
    }
}
