//
//  UIColor+Extensions.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/17/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

private func valueBetween(min: CGFloat, max: CGFloat, progress: CGFloat) -> CGFloat {
    return max - ((max - min) * progress)
}

extension UIColor {
    class func color(from fromColor: UIColor, to toColor: UIColor, progress: CGFloat) -> UIColor? {
        guard
            let fromComponents = fromColor.components,
            let toComponents = toColor.components
            else { return nil }
        let fromRed = fromComponents.red
        let toRed = toComponents.red
        let fromGreen = fromComponents.green
        let toGreen = toComponents.green
        let fromBlue = fromComponents.blue
        let toBlue = toComponents.blue
        let fromAlpha = fromComponents.alpha
        let toAlpha = toComponents.alpha

        let newRed = valueBetween(min: fromRed, max: toRed, progress: progress)
        let newGreen = valueBetween(min: fromGreen, max: toGreen, progress: progress)
        let newBlue = valueBetween(min: fromBlue, max: toBlue, progress: progress)
        let newAlpha = valueBetween(min: fromAlpha, max: toAlpha, progress: progress)
        return UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: newAlpha)
    }
}

extension UIColor {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        return getRed(&r, green: &g, blue: &b, alpha: &a) ? (r, g, b, a) : nil
    }
}
