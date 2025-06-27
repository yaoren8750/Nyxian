//
//  Bootstrap.swift
//  LindDE
//
//  Created by fridakitten on 07.05.25.
//

import Foundation
import ZIPFoundation

/*
 Bootstrap structure
 
 Documents/
  ├── Include/
  ├── SDK/
  ├── Cache/
  ├── Config/
  │   ├── Server/
  │   └── Signature/
  └── Projects/
 */

class Bootstrap {
    var semaphore: DispatchSemaphore?
    let rootPath: String = "\(NSHomeDirectory())/Documents"
    let newestBootstrapVersion: Int = 7
    
    var bootstrapVersion: Int {
        get {
            return UserDefaults.standard.integer(forKey: "LDEBootstrapVersion")
        }
        set {
            let cstep = 1.0 / Double(self.newestBootstrapVersion)
            XCodeButton.updateProgress(progress: cstep * Double(newValue))
            UserDefaults.standard.set(newValue, forKey: "LDEBootstrapVersion")
        }
    }
    
    var isBootstrapInstalled: Bool {
        get {
            return self.bootstrapVersion != 0
        }
    }
    
    func bootstrapPath(_ path: String) -> String {
        var path: String = path
        if path.hasPrefix("/") { path.removeFirst() }
        return URL(fileURLWithPath: path, relativeTo: URL(fileURLWithPath: rootPath)).path
    }
    
    func clearPath(path: String) {
        let fileManager = FileManager.default
        let target = bootstrapPath(path)

        if let files = try? fileManager.contentsOfDirectory(atPath: target) {
            for file in files {
                try? fileManager.removeItem(atPath: "\(target)/\(file)")
            }
        }
    }
    
    func bootstrap() {
        print("[*] Hello LindDE:Bootstrap")
        pthread_dispatch {
            print("[*] install status: \(self.isBootstrapInstalled)")
            print("[*] version: \(self.bootstrapVersion)")
            
            if !self.isBootstrapInstalled ||
                self.bootstrapVersion != self.newestBootstrapVersion {
                
                // "e need to clear the entire path if its not installed
                if !self.isBootstrapInstalled {
                    print("[*] Bootstrap is not installed, clearing")
                    self.clearPath(path: "/")
                }
                
                do {
                    if self.bootstrapVersion == 0 {
                        // Create the folder structure
                        print("[*] Creating folder structures")
                        try FileManager.default.createDirectory(atPath: self.bootstrapPath("/Include"), withIntermediateDirectories: false)
                        try FileManager.default.createDirectory(atPath: self.bootstrapPath("/SDK"), withIntermediateDirectories: false)
                        try FileManager.default.createDirectory(atPath: self.bootstrapPath("/Projects"), withIntermediateDirectories: false)
                        try FileManager.default.createDirectory(atPath: self.bootstrapPath("/Certificates"), withIntermediateDirectories: false)
                        
                        if !fdownload("https://nyxian.app/bootstrap/include.zip", "include.zip") {
                            print("[*] Bootstrap download failed\n")
                            throw NSError(
                                domain: "",
                                code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "Download failed!"]
                            )
                        }
                        
                        // Now extract Include and SDK
                        print("[*] Bootstrapping folder structures")
                        print("[*] Extracting include.zip")
                        try FileManager.default.unzipItem(at: URL(fileURLWithPath: "\(NSTemporaryDirectory())/include.zip"), to: URL(fileURLWithPath: self.bootstrapPath("/Include")))
                        self.bootstrapVersion = 1
                    }
                    
                    if self.bootstrapVersion == 1 {
                        print("[*] bootstrap upgrade patch for version 1")
                        try FileManager.default.createDirectory(atPath: self.bootstrapPath("/Applications"), withIntermediateDirectories: false)
                        self.bootstrapVersion = 2
                    }
                    
                    if self.bootstrapVersion == 2 {
                        print("[*] bootstrap upgrade patch for version 2")
                        try FileManager.default.removeItem(atPath: self.bootstrapPath("/Applications"))
                        try FileManager.default.createDirectory(atPath: self.bootstrapPath("/Config"), withIntermediateDirectories: false)
                        self.bootstrapVersion = 3
                    }
                    
                    if self.bootstrapVersion == 3 {
                        print("[*] bootstrap upgrade patch for version 3")
                        try FileManager.default.createDirectory(atPath: self.bootstrapPath("/Config/Server"), withIntermediateDirectories: false)
                        try FileManager.default.createDirectory(atPath: self.bootstrapPath("/Config/Signature"), withIntermediateDirectories: false)
                        self.bootstrapVersion = 4
                    }
                    
                    if self.bootstrapVersion == 4 {
                        print("[*] bootstrap upgrade patch for version 4")
                        try FileManager.default.createDirectory(atPath: self.bootstrapPath("/Cache"), withIntermediateDirectories: false)
                        self.bootstrapVersion = 5
                    }
                    
                    if self.bootstrapVersion == 5 {
                        print("[*] bootstrap upgrade patch for version 6")
                        // MARK: Placeholder Bootstrap upgrade
                        //getCertificates()
                        self.bootstrapVersion = 6
                    }
                    
                    if self.bootstrapVersion == 6 {
                        if FileManager.default.fileExists(atPath: self.bootstrapPath("/SDK")) {
                            try FileManager.default.removeItem(atPath: self.bootstrapPath("/SDK"))
                        }
                        
                        print("[*] bootstrap upgrade patch for version 7")
                        
                        if !fdownload("https://nyxian.app/bootstrap/sdk18.5.zip", "sdk.zip") {
                            print("[*] Bootstrap download failed\n")
                            throw NSError(
                                domain: "",
                                code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "Download failed!"]
                            )
                        }
                        
                        print("[*] Extracting sdk.zip")
                        try FileManager.default.unzipItem(at: URL(fileURLWithPath: "\(NSTemporaryDirectory())/sdk.zip"), to: URL(fileURLWithPath: self.bootstrapPath("/SDK")))
                        
                        self.bootstrapVersion = 7
                    }
                    
                    self.bootstrapVersion = self.newestBootstrapVersion
                } catch {
                    print("[!] failed: \(error.localizedDescription)")
                    NotificationServer.NotifyUser(level: .error, notification: "Bootstrapping failed: \(error.localizedDescription), you will not be able to build any apps. please restart the app to reattempt bootstrapping!")
                    self.bootstrapVersion = 0
                    self.clearPath(path: "/")
                }
            }
            print("[*] Request Certificates")
            getCertificates()
            print("[*] Done")
        }
    }
    
    func waitTillDone() {
        guard Bootstrap.shared.bootstrapVersion != Bootstrap.shared.newestBootstrapVersion else { return }
        
        XCodeButton.switchImage(systemName: "archivebox.fill")
        XCodeButton.updateProgress(progress: 0.1)
        
        while Bootstrap.shared.bootstrapVersion != Bootstrap.shared.newestBootstrapVersion {
            Thread.sleep(forTimeInterval: 1.0)
        }
        
        XCodeButton.switchImage(systemName: "hammer.fill")
    }
    
    static var shared: Bootstrap = Bootstrap()
}
