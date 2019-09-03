//
//  Appearance.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/16/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

struct GlobalAppearance {

    private static let emptyImage = UIImage()

    static func configure() {
        let navigationBarAppearance = UINavigationBar.appearance()
        navigationBarAppearance.setBackgroundImage(emptyImage, for: .default)
        navigationBarAppearance.shadowImage = emptyImage

        // We set the bar style to black so that our main root navigation has a white status bar, which is the correct
        // color for most of our views.
        navigationBarAppearance.barStyle = .black

        let customBackArrow = #imageLiteral(resourceName: "buttonBackarrow")
        navigationBarAppearance.backIndicatorImage = customBackArrow
        navigationBarAppearance.backIndicatorTransitionMaskImage = customBackArrow
    }
}
