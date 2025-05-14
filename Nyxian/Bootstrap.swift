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
    let bootstrapPath: String = "\(NSHomeDirectory())/Documents"
    let newestBootstrapVersion: Int = 5
    
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
        return "\(bootstrapPath)\(path)"
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
                
                // TODO: If we change the boot architecture we need a system to handle bootstrap upgrades
                do {
                    if self.bootstrapVersion == 0 {
                        // Create the folder structure
                        print("[*] Creating folder structures")
                        try FileManager.default.createDirectory(atPath: self.bootstrapPath("/Include"), withIntermediateDirectories: false)
                        try FileManager.default.createDirectory(atPath: self.bootstrapPath("/SDK"), withIntermediateDirectories: false)
                        try FileManager.default.createDirectory(atPath: self.bootstrapPath("/Projects"), withIntermediateDirectories: false)
                        
                        // Now extract Include and SDK
                        print("[*] Bootstrapping folder structures")
                        print("[*] Extracting include.zip")
                        try FileManager.default.unzipItem(at: URL(fileURLWithPath: "\(Bundle.main.bundlePath)/Shared/include.zip"), to: URL(fileURLWithPath: self.bootstrapPath("/Include")))
                        print("[*] Extracting sdk.zip")
                        try FileManager.default.unzipItem(at: URL(fileURLWithPath: "\(Bundle.main.bundlePath)/Shared/sdk.zip"), to: URL(fileURLWithPath: self.bootstrapPath("/SDK")))
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
                    
                    print("[*] Setting version \(self.bootstrapVersion) -> \(self.newestBootstrapVersion)")
                    self.bootstrapVersion = self.newestBootstrapVersion
                } catch {
                    print("[!] failed: \(error.localizedDescription)")
                    self.bootstrapVersion = 0
                    self.clearPath(path: "/")
                    DispatchQueue.main.async {
                        self.bootstrap()
                    }
                }
            }
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
