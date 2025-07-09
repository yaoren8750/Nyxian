//
//  Project+PlistHelper.swift
//  LindDE
//
//  Created by fridakitten on 08.05.25.
//

import Foundation

class PlistHelper {
    /*
     Holds the values that are needed for the core functionality of the plist helper
     */
    var plistPath: String
    var savedModificationDate: Date
    var lastModificationDate: Date {
        get {
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: plistPath) else { return Date() }
            guard let modDate = attributes[.modificationDate] as? Date else { return Date() }
            return modDate
        }
    }
    
    /*
     Holds the last dictionary
     */
    var dictionary: NSMutableDictionary?
    
    /*
     Holds the reload function that has to be called to reload the content
     */
    var onReload: ([String:Any]) -> Void = { _ in }
    
    init(plistPath: String) {
        self.plistPath = plistPath
        self.savedModificationDate = Date()
        self.savedModificationDate = self.lastModificationDate
    }
    
    /*
     In case that it has been changed not by project settings it gonna be reloaded if the saved modification date is older than the current modification date!
     */
    @discardableResult func reloadIfNeeded() -> Bool {
        let modDate = self.lastModificationDate
        let needsReload: Bool = self.savedModificationDate < modDate
        if needsReload {
            dictionary = NSMutableDictionary(contentsOfFile: plistPath)
            let dict: [String:Any] = (dictionary as? [String:Any]) ?? [:]
            onReload(dict)
            self.savedModificationDate = modDate
        }
        return needsReload
    }
    
    /*
     Functions for the project settings
     */
    func writeKey(key: String, value: Any) {
        if let dictionary = dictionary {
            dictionary[key] = value
            dictionary.write(to: URL(fileURLWithPath: plistPath), atomically: true)
            self.savedModificationDate = Date()
        }
    }
    
    func readKey(key: String) -> Any? {
        if let dictionary = dictionary {
            return dictionary[key]
        }
        return nil
    }
}
