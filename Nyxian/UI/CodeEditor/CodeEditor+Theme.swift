//
//  CodeEditor+Theme.swift
//  LindDE
//
//  Created by fridakitten on 05.05.25.
//

import UIKit
import Runestone

enum HighlightName: String {
    case comment
    case constantBuiltin = "constant.builtin"
    case constantCharacter = "constant.character"
    case constructor
    case function
    case keyword
    case number
    case `operator`
    case property
    case punctuation
    case string
    case type
    case variable
    case variableBuiltin = "variable.builtin"
    case tag

    init?(_ rawHighlightName: String) {
        var comps = rawHighlightName.split(separator: ".")
        while !comps.isEmpty {
            let candidateRawHighlightName = comps.joined(separator: ".")
            if let highlightName = Self(rawValue: candidateRawHighlightName) {
                self = highlightName
                return
            }
            comps.removeLast()
        }
        return nil
    }
}


///
/// Functions to encode and decode Color as RGB String
///

func gibDynamicColor(light: UIColor, dark: UIColor) -> UIColor {
    return UIColor(dynamicProvider: { traits in
        switch traits.userInterfaceStyle {
        case .light, .unspecified:
            return light
            
        case .dark:
            return dark
            
        @unknown default:
            assertionFailure("Unknown userInterfaceStyle: \(traits.userInterfaceStyle)")
            return light
        }
    })
}

extension UIColor {
    convenience init(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat), alpha: Double = 1.0) {
        let light: UIColor = neoRGB(light.0, light.1, light.2).withAlphaComponent(alpha)
        let dark: UIColor = neoRGB(dark.0, dark.1, dark.2).withAlphaComponent(alpha)
        
        self.init(dynamicProvider: { traits in
            switch traits.userInterfaceStyle {
            case .light, .unspecified:
                return light
                
            case .dark:
                return dark
                
            @unknown default:
                assertionFailure("Unknown userInterfaceStyle: \(traits.userInterfaceStyle)")
                return light
            }
        })
    }
}

class LindDEThemer: Theme {
    var fontSize: CGFloat = CGFloat(UserDefaults.standard.double(forKey: "CEFontSize"))
    
    var font: UIFont {
        return UIFont.monospacedSystemFont(ofSize: fontSize, weight: .medium)
    }
    
    var lineNumberFont: UIFont {
        return UIFont.monospacedSystemFont(ofSize: fontSize * 0.85, weight: .regular)
    }
    
    let textColor: UIColor = UIColor(light: (30, 30, 30), dark: (232, 242, 255))
    let backgroundColor: UIColor = UIColor(light: (250, 250, 250), dark: (30, 30, 30))
    
    let gutterBackgroundColor: UIColor = UIColor(light: (240, 240, 240), dark: (25, 25, 25))
    let gutterHairlineColor: UIColor = UIColor(light: (220, 220, 220), dark: (50, 50, 50))
    
    let lineNumberColor: UIColor = UIColor(light: (180, 180, 180), dark: (90, 90, 90))
    
    let selectedLineBackgroundColor: UIColor = UIColor(light: (220, 230, 250), dark: (40, 44, 52), alpha: 0.8)
    let selectedLinesLineNumberColor: UIColor = UIColor(light: (80, 120, 180), dark: (130, 180, 255))
    let selectedLinesGutterBackgroundColor: UIColor = UIColor(light: (235, 235, 240), dark: (20, 20, 25))
    
    var invisibleCharactersColor: UIColor {
        return textColor.withAlphaComponent(0.25)
    }
    
    let pageGuideHairlineColor: UIColor = UIColor(light: (220, 220, 230), dark: (45, 45, 50))
    let pageGuideBackgroundColor: UIColor = UIColor(light: (245, 245, 250), dark: (30, 30, 35))
    
    var markedTextBackgroundColor: UIColor = UIColor(light: (230, 240, 250), dark: (60, 60, 70))
    let colorKeyword: UIColor = UIColor(light: (0, 0, 192), dark: (86, 156, 214))
    let colorComment: UIColor = UIColor(light: (0, 128, 0), dark: (106, 153, 85))
    let colorString: UIColor = UIColor(light: (163, 21, 21), dark: (206, 145, 120))
    let colorNumber: UIColor = UIColor(light: (128, 0, 128), dark: (181, 206, 168))
    let colorRegex: UIColor = UIColor(light: (255, 140, 0), dark: (255, 198, 109))
    let colorFunction: UIColor = UIColor(light: (43, 145, 175), dark: (220, 220, 170))
    let colorOperator: UIColor = UIColor(light: (0, 0, 0), dark: (212, 212, 212))
    let colorProperty: UIColor = UIColor(light: (0, 0, 128), dark: (156, 220, 254))
    let colorPunctuation: UIColor = UIColor(light: (50, 50, 50), dark: (200, 200, 200))
    let colorDirective: UIColor = UIColor(light: (60, 60, 60), dark: (255, 165, 0))
    let colorType: UIColor = UIColor(light: (43, 43, 150), dark: (78, 201, 176))
    let colorConstantBuiltin: UIColor = UIColor(light: (75, 0, 130), dark: (0, 255, 255))
    
    func textColor(for highlightName: String) -> UIColor? {
        guard let highlightName = HighlightName(highlightName) else {
            return nil
        }
        switch highlightName {
        case .keyword:
            return colorKeyword
        case .constantBuiltin:
            return colorConstantBuiltin
        case .number:
            return colorNumber
        case .comment:
            return colorComment
        case .operator:
            return colorOperator
        case .string:
            return colorString
        case .function, .variable:
            return colorFunction
        case .property:
            return colorProperty
        case .punctuation:
            return colorPunctuation
        case .type:
            return colorType
        case .tag:
            return colorString
        default:
            return textColor
        }
    }
}

func neoRGB(_ red: CGFloat,_ green: CGFloat,_ blue: CGFloat ) -> UIColor {
    return UIColor(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: 1.0)
}
