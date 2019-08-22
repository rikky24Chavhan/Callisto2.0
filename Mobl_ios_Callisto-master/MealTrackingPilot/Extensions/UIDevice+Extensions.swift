//
//  UIDevice+Extensions.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/27/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

extension UIDevice {
    public enum ScreenType {
        case small // iPhone 5, 5s, SE
        case medium // iPhone 6, 6s, 7, 8
        case large // iPhone 6+, 6s+, 7+, 8+
        case notch // iPhone X
    }

    var isSmall: Bool {
        return isSmallWidth || isSmallHeight
    }

    var isSmallWidth: Bool {
        // Check window size to future-proof (E.G. iPad multitasking modes)
        let width = UIApplication.shared.keyWindow?.bounds.width ?? UIScreen.main.bounds.width
        return width <= 320
    }

    var isSmallHeight: Bool {
        let height = UIApplication.shared.keyWindow?.bounds.height ?? UIScreen.main.bounds.height
        return height <= 568
    }

    var screenType: ScreenType {
        switch UIScreen.main.bounds.height {
        case let height where height > 736:
            return .notch
        case let height where height == 736:
            return .large
        case let height where height == 667:
            return .medium
        default:
            return .small
        }
    }

    var isRunningiOS10: Bool {
        return systemVersion.starts(with: "10")
    }
}
