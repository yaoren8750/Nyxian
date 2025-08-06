/*
 Copyright (C) 2025 cr4zyengineer
 Copyright (C) 2025 expo

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

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
