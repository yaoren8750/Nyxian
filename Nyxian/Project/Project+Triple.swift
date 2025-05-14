//
//  Project+Triple..swift
//  LindDE
//
//  Created by fridakitten on 07.05.25.
//

import UIKit
import Foundation

func getPlatformTriple() -> String {
    // MARK: For platform reasons as the Bootstrap SDK shipped is using the iPhoneOS16.5 SDK we need to check the platform version
    if #available(iOS 16.5, *) {
        return "16.5"
    } else {
        return UIDevice.current.systemVersion
    }
}
