//
//  Extension+Font.swift
//  Calibrate
//
//  Created by Hadi on 21/10/2024.
//

import SwiftUICore

extension Font {
    
    static func DMSans(weight: FontType, size: CGFloat) -> Font {
        return Font.custom("DMSans-\(weight.rawValue)", size: size) // DMSans-Bold"
    }
    
    static func Gilroy(weight: FontType, size: CGFloat) -> Font {
        return Font.custom("Gilroy-\(weight.rawValue)", size: size) // "Gilroy-Bold"
    }
}

enum FontType: String {
    case regular = "Regular"
    case bold = "Bold"
    case medium = "Medium"
    case semiBold = "SemiBold"
}


