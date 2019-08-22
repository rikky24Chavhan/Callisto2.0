//
//  UIBarButtonItem+EmptyTitle.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/7/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
    class func emptyBackItem(target: Any? = nil, selector: Selector? = nil) -> UIBarButtonItem {
        return UIBarButtonItem(title: "", style: .plain, target: target, action: selector)
    }

    class func emptyItem(withWidth width: CGFloat) -> UIBarButtonItem {
        let emptySpace = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 0))
        emptySpace.backgroundColor = .clear
        return UIBarButtonItem(customView: emptySpace)
    }
}
