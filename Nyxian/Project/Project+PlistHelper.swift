//
//  Project+PlistHelper.swift
//  LindDE
//
//  Created by fridakitten on 08.05.25.
//

import Foundation

class PlistHelper {
    var plistPath: String
    var savedModificationDate: Date
    var lastModificationDate: Date {
        get {
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: plistPath) else { return Date() }
            guard let modDate = attributes[.modificationDate] as? Date else { return Date() }
            return modDate
        }
    }
    
    var onReload: ([String:Any]) -> Void = { _ in }
    
    init(plistPath: String) {
        self.plistPath = plistPath
        self.savedModificationDate = Date()
        
        self.savedModificationDate = self.lastModificationDate
    }
    
    func reloadIfNeeded() {
        print("[*] Hello LindDE:PlistHelper")
        let modDate = self.lastModificationDate
        if self.savedModificationDate < modDate {
            print("[*] plist was modified")
            let dict: [String:Any] = (NSDictionary(contentsOfFile: plistPath) as? [String:Any]) ?? [:]
            onReload(dict)
            self.savedModificationDate = modDate
        }
    }
}
