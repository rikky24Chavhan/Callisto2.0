//
//  OccasionPicker+Helpers.swift
//  MealTrackingPilot
//
//  Created by Gowtham on 23/09/19.
//  Copyright © 2019 LTTS. All rights reserved.
//

import Foundation
import UIKit

/**
 ScrollingStyle Enum.
 - parameter Default: Show only the number of items informed in data source.
 - parameter Infinite: Loop through the data source offering a infinite scrolling experience to the user.
 */

@objc public enum ScrollingStyle: Int {
    case `default`
    case infinite
}

/**
 ScrollingDirection Enum.
 - parameter horizontal: Loads picker items with horizontal scrolling
 - parameter vertical: Loads picker items with vertical scrolling
 */

@objc public enum ScrollingDirection: Int {
    case horizontal
    case vertical
    
    func opposite() -> ScrollingDirection {
        return self == .horizontal ? .vertical : .horizontal
    }
    
    func collectionViewScrollDirection() -> UICollectionView.ScrollDirection {
        return self == .horizontal ? .horizontal : .vertical
    }
    
    func spanLayoutAttribute() -> NSLayoutConstraint.Attribute {
        return self == .horizontal ? .width : .height
    }
    
    func lateralSpanLayoutAttribute() -> NSLayoutConstraint.Attribute {
        return opposite().spanLayoutAttribute()
    }
}
