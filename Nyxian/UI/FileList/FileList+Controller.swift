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
    static var mode: PasteBoardServices.Mode = .copy
    
    static func copy(mode: PasteBoardServices.Mode, path: String) {
        PasteBoardServices.path = path
        PasteBoardServices.mode = mode
    }
    
    static func paste(path: String) {
        // Craft full path
        let fileName: String = URL(fileURLWithPath: self.path).lastPathComponent
        let dest: String = URL(fileURLWithPath: path).appendingPathComponent(fileName).path
        
        // Now copy/move it
        if PasteBoardServices.mode == .copy {
            try? FileManager.default.copyItem(atPath: self.path, toPath: dest)
        } else {
            try? FileManager.default.moveItem(atPath: self.path, toPath: dest)
        }
    }
}
