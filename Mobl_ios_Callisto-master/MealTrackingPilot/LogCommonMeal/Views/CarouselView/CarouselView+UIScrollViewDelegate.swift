//
//  CarouselView+UIScrollViewDelegate.swift
//  CarouselView
//
//  Created by Rikky Chavhan on 20/08/19.
//  Copyright © 2019 L&T. All rights reserved.
//

import UIKit

extension CarouselView: UIScrollViewDelegate {
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // Get the estimative of what row will be the selected when the scroll animation ends.
        let partialItem = Float((targetContentOffset.pointee.offset(forDirection: scrollingDirection) + endCapSpan) / itemSpan)
        var roundedItem = Int(lroundf(partialItem)) // Round the estimative to a row
        if roundedItem < 0 {
            roundedItem = 0
        }
        
        // Set the targetContentOffset (where the scrolling position will be when the animation ends) to a rounded value.
        targetContentOffset.pointee.setOffset(CGFloat(roundedItem) * itemSpan - endCapSpan, forDirection: scrollingDirection)
        
        // Update the currentSelectedItem and notify the delegate that we have a new selected row.
        currentSelectedItem = roundedItem % numberOfItemsByDataSource
        delegate?.carouselView(self, didSelectItem: currentSelectedItem, index: currentSelectedIndex)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // When the orientation changes during the scroll, is required to reset the picker to select the nearby to middle row.
        if orientationChanged {
            selectedNearbyToMiddleItem(currentSelectedItem)
            orientationChanged = false
        }
        isScrolling = false
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let partialItem = Float((scrollView.contentOffset.offset(forDirection: scrollingDirection) + endCapSpan) / itemSpan)
        let roundedItem = Int(lroundf(partialItem))
        
        // Avoid to have two highlighted rows at the same time
        let visibleItems = collectionView.indexPathsForVisibleItems
        for indexPath in visibleItems {
            if let cellToUnhighlight = collectionView.cellForItem(at: indexPath) as? CarouselCollectionViewCell , indexPath.item != roundedItem {
                _ = delegate?.carouselView(self, viewForItem: indexPath.item, index: indexForItem(indexPath.item), highlighted: false, reusingView: cellToUnhighlight.customView)
            }
        }
        
        // Highlight the current selected cell during scroll
        if let cellToHighlight = collectionView.cellForItem(at: IndexPath(item: roundedItem, section: 0)) as? CarouselCollectionViewCell {
            _ = delegate?.carouselView(self, viewForItem: roundedItem, index: indexForItem(roundedItem), highlighted: true, reusingView: cellToHighlight.customView)
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isAnimating = false
    }
}
