//
//  String+fileURL.swift
//  LindDE
//
//  Created by fridakitten on 06.05.25.
//

import Foundation

extension String {
    func URLGet() -> URL {
        return URL(fileURLWithPath: self)
    }
    
    func URLLastPathComponent() -> String {
        return self.URLGet().lastPathComponent
    }
}
