//
//  FileList+Controller.swift
//  Nyxian
//
//  Created by SeanIsTethered on 18.05.25.
//

import Foundation

class PasteBoardServices {
    enum Mode {
        case copy
        case move
    }
    
    static var path: String = ""
    static var onMove: () -> Void = {}
    static var mode: PasteBoardServices.Mode = .copy
    
    static func copy(mode: PasteBoardServices.Mode, path: String) {
        PasteBoardServices.path = path
        PasteBoardServices.mode = mode
    }
    
    static func paste(path: String) {
        if PasteBoardServices.path != "0" {
            // Craft full path
            let fileName: String = URL(fileURLWithPath: self.path).lastPathComponent
            let dest: String = URL(fileURLWithPath: path).appendingPathComponent(fileName).path
            
            // Overwrite automatically if exists
            if FileManager.default.fileExists(atPath: dest) {
                try? FileManager.default.removeItem(atPath: dest)
            }
            
            // Now copy/move it
            if PasteBoardServices.mode == .copy {
                try? FileManager.default.copyItem(atPath: self.path, toPath: dest)
            } else {
                try? FileManager.default.moveItem(atPath: self.path, toPath: dest)
                PasteBoardServices.onMove()
            }
            
            // Unregister onMove action
            PasteBoardServices.onMove = {}
            PasteBoardServices.path = "0"
        } else {
            print("PasteBoardServices:Error: Nothing to do here")
        }
    }
    
    static func needPaste() -> Bool {
        return (PasteBoardServices.path != "0")
    }
}
