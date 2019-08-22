//
//  OpenSansSwift.swift
//  OpenSansSwift
//
//  Created by Hemanta Sapkota on 17/02/2015.
//  Copyright (c) 2015 Open Learning Pty Ltd. All rights reserved.
//

import UIKit
import CoreText

protocol UIFontOpenSans {

    static func openSansFont(size: Float) -> UIFont

    static func openSansBoldFont(size: Float) -> UIFont

    static func openSansBoldItalicFont(size: Float) -> UIFont

    static func openSansExtraBoldFont(size: Float) -> UIFont

    static func openSansExtraBoldItalicFont(size: Float) -> UIFont

    static func openSansItalicFont(size: Float) -> UIFont

    static func openSansLightFont(size: Float) -> UIFont

    static func openSansLightItalicFont(size: Float) -> UIFont

    static func openSansSemiboldFont(size: Float) -> UIFont

    static func openSansSemiboldItalicFont(size: Float) -> UIFont

}

extension UIFont : UIFontOpenSans {

    public class func openSansFont(size: Float) -> UIFont {
        return UIFont(name: "OpenSans", size: makeSize(size))!
    }

    public class func openSansBoldFont(size: Float) -> UIFont {
        return UIFont(name: "OpenSans-Bold", size: makeSize(size))!
    }

    public class func openSansBoldItalicFont(size: Float) -> UIFont {
        return UIFont(name: "OpenSans-BoldItalic", size: makeSize(size))!
    }

    public class func openSansExtraBoldFont(size: Float) -> UIFont {
        return UIFont(name: "OpenSans-Extrabold", size: makeSize(size))!
    }

    public class func openSansExtraBoldItalicFont(size: Float) -> UIFont {
        return UIFont(name: "OpenSans-ExtraboldItalic", size: makeSize(size))!
    }

    public class func openSansItalicFont(size: Float) -> UIFont {
        return UIFont(name: "OpenSans-Italic", size: makeSize(size))!
    }

    public class func openSansLightFont(size: Float) -> UIFont {
        return UIFont(name: "OpenSans-Light", size: makeSize(size))!
    }

    public class func openSansLightItalicFont(size: Float) -> UIFont {
        return UIFont(name: "OpenSansLight-Italic", size: makeSize(size))!
    }

    public class func openSansSemiboldFont(size: Float) -> UIFont {
        return UIFont(name: "OpenSans-Semibold", size: makeSize(size))!
    }

    public class func openSansSemiboldItalicFont(size: Float) -> UIFont {
        return UIFont(name: "OpenSans-SemiboldItalic", size: makeSize(size))!
    }

    class func makeSize(_ size: Float) -> CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return CGFloat(size * OpenSans.retinaScaleFactor)
        }

        return CGFloat(size)
    }

}

public class OpenSans {

    /// scale factor for retina devices. Default 2.0
    public static var retinaScaleFactor: Float = 2.0

    public class func registerFonts() -> Bool {
        let fontNames = [
            "OpenSans-Regular",
            "OpenSans-Bold",
            "OpenSans-BoldItalic",
            "OpenSans-ExtraBold",
            "OpenSans-ExtraBoldItalic",
            "OpenSans-Italic",
            "OpenSans-Light",
            "OpenSans-LightItalic",
            "OpenSans-Semibold",
            "OpenSans-SemiboldItalic"
        ]

        var error: Unmanaged<CFError>? = nil

        for font in fontNames {
            let url = Bundle(for: OpenSans.self).url(forResource: font, withExtension: "ttf")
            if (url != nil) {
                CTFontManagerRegisterFontsForURL(url! as CFURL, .none, &error)
            }
        }

        return error == nil
    }
}
