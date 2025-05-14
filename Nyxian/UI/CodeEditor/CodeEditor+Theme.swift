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

class LindDEThemer: Theme {
    var fontSize: CGFloat = CGFloat(UserDefaults.standard.double(forKey: "CEFontSize"))
    
    var font: UIFont {
        return UIFont.monospacedSystemFont(ofSize: fontSize, weight: .medium)
    }
    
    var lineNumberFont: UIFont {
        return UIFont.monospacedSystemFont(ofSize: fontSize * 0.85, weight: .regular)
    }
    
    var textColor: UIColor
    var backgroundColor: UIColor
    
    var gutterBackgroundColor: UIColor
    var gutterHairlineColor: UIColor
    
    var lineNumberColor: UIColor
    
    var selectedLineBackgroundColor: UIColor
    var selectedLinesLineNumberColor: UIColor
    var selectedLinesGutterBackgroundColor: UIColor
    
    var invisibleCharactersColor: UIColor
    
    var pageGuideHairlineColor: UIColor
    var pageGuideBackgroundColor: UIColor
    
    var markedTextBackgroundColor: UIColor
    
    let colorKeyword: UIColor
    let colorComment: UIColor
    let colorString: UIColor
    let colorNumber: UIColor
    let colorRegex: UIColor
    let colorFunction: UIColor
    let colorOperator: UIColor
    let colorProperty: UIColor
    let colorPunctuation: UIColor
    let colorDirective: UIColor
    let colorType: UIColor
    let colorConstantBuiltin: UIColor
    
    init() {
        backgroundColor = gibDynamicColor(
            light:  neoRGB(250, 250, 250),
            dark:   neoRGB(30, 30, 30)
        )
        textColor = gibDynamicColor(
            light:  neoRGB(30, 30, 30),
            dark:   neoRGB(232, 242, 255)
        )
        gutterBackgroundColor = gibDynamicColor(
            light:  neoRGB(240, 240, 240),
            dark:   neoRGB(25, 25, 25)
        )
        gutterHairlineColor = gibDynamicColor(
            light:  neoRGB(220, 220, 220),
            dark:   neoRGB(50, 50, 50)
        )
        lineNumberColor = gibDynamicColor(
            light:  neoRGB(180, 180, 180),
            dark:   neoRGB(90, 90, 90)
        )
        selectedLineBackgroundColor = gibDynamicColor(
            light:  neoRGB(220, 230, 250).withAlphaComponent(0.8),
            dark:   neoRGB(40, 44, 52).withAlphaComponent(0.8)
        )
        selectedLinesLineNumberColor = gibDynamicColor(
            light:  neoRGB(80, 120, 180),
            dark:   neoRGB(130, 180, 255)
        )
        selectedLinesGutterBackgroundColor = gibDynamicColor(
            light:  neoRGB(235, 235, 240),
            dark:   neoRGB(20, 20, 25)
        )
        pageGuideHairlineColor = gibDynamicColor(
            light:  neoRGB(220, 220, 230),
            dark:   neoRGB(45, 45, 50)
        )
        pageGuideBackgroundColor = gibDynamicColor(
            light:  neoRGB(245, 245, 250),
            dark:   neoRGB(30, 30, 35)
        )
        markedTextBackgroundColor = gibDynamicColor(
            light:  neoRGB(230, 240, 250),
            dark:   neoRGB(60, 60, 70)
        )
        colorKeyword = gibDynamicColor(
            light:  neoRGB(0, 0, 192),
            dark:   neoRGB(86, 156, 214)
        )
        colorComment = gibDynamicColor(
            light:  neoRGB(0, 128, 0),
            dark:   neoRGB(106, 153, 85)
        )
        colorString = gibDynamicColor(
            light:  neoRGB(163, 21, 21),
            dark:   neoRGB(206, 145, 120)
        )
        colorNumber = gibDynamicColor(
            light:  neoRGB(128, 0, 128),
            dark:   neoRGB(181, 206, 168)
        )
        colorRegex = gibDynamicColor(
            light:  neoRGB(255, 140, 0),
            dark:   neoRGB(255, 198, 109)
        )
        colorFunction = gibDynamicColor(
            light:  neoRGB(43, 145, 175),
            dark:   neoRGB(220, 220, 170)
        )
        colorOperator = gibDynamicColor(
            light:  neoRGB(0, 0, 0),
            dark:   neoRGB(212, 212, 212)
        )
        colorProperty = gibDynamicColor(
            light:  neoRGB(0, 0, 128),
            dark:   neoRGB(156, 220, 254)
        )
        colorPunctuation = gibDynamicColor(
            light:  neoRGB(50, 50, 50),
            dark:   neoRGB(200, 200, 200)
        )
        colorDirective = gibDynamicColor(
            light:  neoRGB(60, 60, 60),
            dark:   neoRGB(255, 165, 0)
        )
        colorType = gibDynamicColor(
            light:  neoRGB(43, 43, 150),
            dark:   neoRGB(78, 201, 176)
        )
        colorConstantBuiltin = gibDynamicColor(
            light:  neoRGB(75, 0, 130),
            dark:   neoRGB(0, 255, 255)
        )
        
        invisibleCharactersColor = textColor.withAlphaComponent(0.25)
    }
    
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
