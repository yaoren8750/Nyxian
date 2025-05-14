//
//  CleanTemporary.swift
//  Nyxian
//
//  Created by fridakitten on 14.04.25.
//

import Foundation

func cleanTmp() {
    let fileManager = FileManager.default
    let tmpDirectory = NSHomeDirectory() + "/tmp"

    if let files = try? fileManager.contentsOfDirectory(atPath: tmpDirectory) {
        for file in files {
            try? fileManager.removeItem(atPath: tmpDirectory + "/" + file)
        }
    }
}
