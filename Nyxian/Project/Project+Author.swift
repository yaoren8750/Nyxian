//
//  Project+FileSignature.swift
//  LindDE
//
//  Created by fridakitten on 06.05.25.
//

import Foundation

class Author {
    var author: String = ""
    var file: String = ""
    var project: String = ""
    var signature: String {
        get {
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yy"
            let formattedDate = formatter.string(from: date)
            return "//\n// \(file)\n// \(project)\n//\n// Created by \(self.author) on \(formattedDate).\n//\n\n"
        }
    }
    
    func setTargetProject(_ name: String) {
        project = name
    }
    
    func signatureForFile(_ name: String) -> String {
        self.author = (UserDefaults.standard.object(forKey: "LDEUsername") as? String) ?? "Anonym"
        
        file = name
        return signature
    }
    
    static var shared: Author = Author()
}
