//
//  Project+FileSignature.swift
//  LindDE
//
//  Created by fridakitten on 06.05.25.
//

import Foundation

class Author {
    private var _author: String = ""
    var author: String {
        get {
            return self._author
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "LDEFileAuthor")
            _author = newValue
        }
    }
    
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
    
    init() {
        let author = UserDefaults.standard.object(forKey: "LDEFileAuthor") as? String
        self._author = author ?? "Anonym"
    }
    
    func setTargetProject(_ name: String) {
        project = name
    }
    
    func signatureForFile(_ name: String) -> String {
        file = name
        return signature
    }
    
    static var shared: Author = Author()
}
