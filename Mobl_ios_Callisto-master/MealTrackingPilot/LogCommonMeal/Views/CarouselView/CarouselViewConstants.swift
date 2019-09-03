//
//  CarouselViewConstants.swift
//  CarouselView
//
//  Created by Rikky Chavhan on 20/08/19.
//  Copyright © 2019 L&T. All rights reserved.
//

import UIKit

public enum CarouselViewConstants  {
    static let carouselViewCellIdentifier = "pickerViewCell"
}

/**
 ScrollingStyle Enum.
 - parameter Default: Show only the number of rows informed in data source.
 - parameter Infinite: Loop through the data source offering a infinite scrolling experience to the user.
 */

public enum ScrollingStyle: Int {
    case `default`, infinite
}

public enum ScrollingDirection: Int {
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

/**
 SelectionStyle Enum.
 
 - parameter None: Don't uses any aditional view to highlight the selection, only the label style customization provided by delegate.
 
 - parameter DefaultIndicator: Provide a simple selection indicator on the bottom of the highlighted row with full width and 2pt of height.
 The default color is its superview `tintColor` but you have free access to customize the DefaultIndicator through the `defaultSelectionIndicator` property.
 
 - parameter Overlay: Provide a full width and height (the height you provided on delegate) view that overlay the highlighted row.
 The default color is its superview `tintColor` and the alpha is set to 0.25, but you have free access to customize it through the `selectionOverlay` property.
 Tip: You can set the alpha to 1.0 and background color to .clearColor() and add your custom selection view to make it looks as you want
 (don't forget to properly add the constraints related to `selectionOverlay` to keep your experience with any screen size).
 
 - parameter Image: Provide a full width and height image view selection indicator (the height you provided on delegate) without any image.
 You must have a selection indicator as a image and set it to the image view through the `selectionImageView` property.
 */

public enum SelectionStyle: Int {
    case none, defaultIndicator, overlay, image
}
