//
//  OccasionPicker+Extensions.swift
//  MealTrackingPilot
//
//  Created by Gowtham on 23/09/19.
//  Copyright © 2019 Intrepid. All rights reserved.
//

import Foundation
import UIKit

extension OccasionPicker: UICollectionViewDataSource {
    
    // MARK: UICollectionViewDataSource
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItemsByDataSource * infinityItemsMultiplier
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let indexOfSelectedItem = visibleIndexOfSelectedItem()
        
        let occasionPickerCell = collectionView.dequeueReusableCell(withReuseIdentifier: occasionPickerCellIdentifier, for: indexPath) as! OccasionPickerCollectionViewCell
        
        let view = delegate?.occasionPicker?(self, viewForItem: indexPath.item, index: indexForItem(indexPath.item), highlighted: indexPath.item == indexOfSelectedItem, reusingView: occasionPickerCell.customView)
        
        occasionPickerCell.backgroundColor = pickerCellBackgroundColor ?? UIColor.clear
        
        if let customView = view {
            occasionPickerCell.customView = customView
        } else {
            let size = CGSize(span: itemSpan, lateralSpan: itemLateralSpan, direction: scrollingDirection)
            occasionPickerCell.titleLabel.frame = CGRect(origin: .zero, size: size)
            
            occasionPickerCell.contentView.addSubview(occasionPickerCell.titleLabel)
            occasionPickerCell.titleLabel.backgroundColor = UIColor.clear
            occasionPickerCell.titleLabel.text = dataSource?.occasionPicker(self, titleForItem: indexPath.item, index: indexForItem(indexPath.item))
            
            delegate?.occasionPicker?(self, styleForLabel: occasionPickerCell.titleLabel, highlighted: indexPath.item == indexOfSelectedItem)
        }
        
        return occasionPickerCell
    }
}

extension OccasionPicker: UICollectionViewDelegate {
    
    // MARK: UICollectionViewDelegate
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectTappedItem(indexPath.item)
    }
}

extension OccasionPicker: UICollectionViewDelegateFlowLayout {
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let lateralSpan = bounds.size.lateralSpan(forDirection: scrollingDirection)
        return CGSize(span: itemSpan, lateralSpan: lateralSpan, direction: scrollingDirection)
    }
}

extension OccasionPicker: UIScrollViewDelegate {
    
    // MARK: UIScrollViewDelegate
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // Get the estimative of what item will be the selected when the scroll animation ends.
        let partialItem = Float((targetContentOffset.pointee.offset(forDirection: scrollingDirection) + endCapSpan) / itemSpan)
        var roundedItem = Int(lroundf(partialItem)) // Round the estimative to an item
        
        if roundedItem < 0 {
            roundedItem = 0
        }
        
        // Set the targetContentOffset (where the scrolling position will be when the animation ends) to a rounded value.
        targetContentOffset.pointee.setOffset(CGFloat(roundedItem) * itemSpan - endCapSpan, forDirection: scrollingDirection)
        
        // Update the currentSelectedItem and notify the delegate that we have a new selected item.
        currentSelectedItem = roundedItem % numberOfItemsByDataSource
        
        delegate?.occasionPicker?(self, didSelectItem: currentSelectedItem, index: currentSelectedIndex)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrolling = false
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let partialItem = Float((scrollView.contentOffset.offset(forDirection: scrollingDirection) + endCapSpan) / itemSpan)
        let roundedItem = Int(lroundf(partialItem))
        
        // Avoid to have two highlighted items at the same time
        let visibleItems = collectionView.indexPathsForVisibleItems
        for indexPath in visibleItems {
            if let cellToUnhighlight = collectionView.cellForItem(at: indexPath) as? OccasionPickerCollectionViewCell , indexPath.item != roundedItem {
                _ = delegate?.occasionPicker?(self, viewForItem: indexPath.item, index: indexForItem(indexPath.item), highlighted: false, reusingView: cellToUnhighlight.customView)
                delegate?.occasionPicker?(self, styleForLabel: cellToUnhighlight.titleLabel, highlighted: false)
            }
        }
        
        // Highlight the current selected item during scroll
        if let cellToHighlight = collectionView.cellForItem(at: IndexPath(item: roundedItem, section: 0)) as? OccasionPickerCollectionViewCell {
            _ = delegate?.occasionPicker?(self, viewForItem: roundedItem, index: indexForItem(roundedItem), highlighted: true, reusingView: cellToHighlight.customView)
            delegate?.occasionPicker?(self, styleForLabel: cellToHighlight.titleLabel, highlighted: true)
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isAnimating = false
    }
}
