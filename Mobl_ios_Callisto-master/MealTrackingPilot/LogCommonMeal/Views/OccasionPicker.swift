//
//  OccasionPicker.swift
//  MealTrackingPilot
//
//  Created by Gowtham on 17/09/19.
//  Copyright © 2019 LTTS. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Protocols

@objc public protocol OccasionPickerDataSource: class {
    func occasionPickerNumberOfItems(_ occasionPicker: OccasionPicker) -> Int
    func occasionPicker(_ occasionPicker: OccasionPicker, titleForItem item: Int, index: Int) -> String
}

@objc public protocol OccasionPickerDelegate: class {
    func occasionPickerSpanForItems(_ occasionPicker: OccasionPicker) -> CGFloat
    @objc optional func occasionPicker(_ occasionPicker: OccasionPicker, didSelectItem item: Int, index: Int)
    @objc optional func occasionPicker(_ occasionPicker: OccasionPicker, didTapItem item: Int, index: Int)
    @objc optional func occasionPicker(_ occasionPicker: OccasionPicker, styleForLabel label: UILabel, highlighted: Bool)
    @objc optional func occasionPicker(_ occasionPicker: OccasionPicker, viewForItem item: Int, index: Int, highlighted: Bool, reusingView view: UIView?) -> UIView?
    @objc optional func occasionPickerWillBeginMoving(_ occasionPicker: OccasionPicker)
    @objc optional func occasionPickerDidEndMoving(_ occasionPicker: OccasionPicker)
}

public class OccasionPicker: UIView {

    // MARK: Picker Properties
    
    var enabled = true {
        didSet {
            if enabled {
                turnOccasionPickerOn()
            } else {
                turnOccasionPickerOff()
            }
        }
    }
    
    private var selectionOverlaySpanConstraint: NSLayoutConstraint!
    private var selectionImageSpanConstraint: NSLayoutConstraint!
    private var selectionIndicatorEdgeConstraint: NSLayoutConstraint!
    private var pickerCellBackgroundColor: UIColor?
    
    var numberOfItemsByDataSource: Int {
        get {
            return dataSource?.occasionPickerNumberOfItems(self) ?? 0
        }
    }
    
    private let occasionPickerCellIdentifier = "occasionPickerCell"
    
    weak var dataSource: OccasionPickerDataSource?
    weak var delegate: OccasionPickerDelegate?
    
    lazy var selectionIndicator: UIView = {
        let selectionIndicator = UIView()
        selectionIndicator.backgroundColor = self.tintColor
        selectionIndicator.alpha = 0.0
        
        return selectionIndicator
    }()
    
    lazy var selectionOverlay: UIView = {
        let selectionOverlay = UIView()
        selectionOverlay.backgroundColor = self.tintColor
        selectionOverlay.alpha = 0.0
        
        return selectionOverlay
    }()
    
    lazy var selectionImageView: UIImageView = {
        let selectionImageView = UIImageView()
        selectionImageView.alpha = 0.0
        
        return selectionImageView
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        return collectionView
    }()
    
    var currentSelectedItem: Int!
    var currentSelectedIndex: Int {
        get {
            return indexForItem(currentSelectedItem)
        }
    }
    
    private var infinityItemsMultiplier: Int = 1
    private var setupHasBeenDone = false
    
    private var isScrolling = false {
        didSet {
            trackMovementChanges()
        }
    }
    
    private var isAnimating = false {
        didSet {
            trackMovementChanges()
        }
    }
    
    var scrollingStyle = ScrollingStyle.default {
        didSet {
            switch scrollingStyle {
            case .default:
                infinityItemsMultiplier = 1
            case .infinite:
                infinityItemsMultiplier = generateInfinityItemsMultiplier()
            }
        }
    }
    
    var scrollingDirection = ScrollingDirection.vertical {
        didSet {
            if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.scrollDirection = scrollingDirection.collectionViewScrollDirection()
            }
        }
    }
    
    // MARK: Initialization
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // MARK: Subviews Setup
    
    private func configureSetup() {
        infinityItemsMultiplier = generateInfinityItemsMultiplier()
        
        translatesAutoresizingMaskIntoConstraints = false
        
        // Setup subview constraints and apperance
        setupCollectionView()
        setupSelectionOverlay()
        setupSelectionImageView()
        setupSelectionIndicator()
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.configureFirstSelection()
            self.adjustSelectionOverlayHeightConstraint()
        }
    }
    
    private func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.scrollsToTop = false
        collectionView.register(OccasionPickerCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: self.occasionPickerCellIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.reloadData()
        
        let collectionViewWidth = NSLayoutConstraint(item: collectionView, attribute: .width, relatedBy: .equal, toItem: self,
                                                     attribute: .width, multiplier: 1, constant: 0)
        addConstraint(collectionViewWidth)
        
        let collectionViewHeight = NSLayoutConstraint(item: collectionView, attribute: .height, relatedBy: .equal, toItem: self,
                                                      attribute: .height, multiplier: 1, constant: 0)
        addConstraint(collectionViewHeight)
        
        let collectionViewLeading = NSLayoutConstraint(item: collectionView, attribute: .leading, relatedBy: .equal, toItem: self,
                                                       attribute: .leading, multiplier: 1, constant: 0)
        addConstraint(collectionViewLeading)
        
        let collectionViewTrailing = NSLayoutConstraint(item: collectionView, attribute: .trailing, relatedBy: .equal, toItem: self,
                                                        attribute: .trailing, multiplier: 1, constant: 0)
        addConstraint(collectionViewTrailing)
        
        let collectionViewTop = NSLayoutConstraint(item: collectionView, attribute: .top, relatedBy: .equal, toItem: self,
                                                   attribute: .top, multiplier: 1, constant: 0)
        addConstraint(collectionViewTop)
        
        let collectionViewBottom = NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: self,
                                                      attribute: .bottom, multiplier: 1, constant: 0)
        addConstraint(collectionViewBottom)
    }
    
    private func setupSelectionOverlay() {
        selectionOverlay.isUserInteractionEnabled = false
        selectionOverlay.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(selectionOverlay)
        
        let spanAttribute = scrollingDirection.spanLayoutAttribute()
        selectionOverlaySpanConstraint = NSLayoutConstraint(item: selectionOverlay, attribute: spanAttribute, relatedBy: .equal, toItem: nil,
                                                            attribute: .notAnAttribute, multiplier: 1, constant: itemSpan)
        self.addConstraint(selectionOverlaySpanConstraint)
        
        let lateralSpanAttribute = scrollingDirection.lateralSpanLayoutAttribute()
        let selectionOverlayLateral = NSLayoutConstraint(item: selectionOverlay, attribute: lateralSpanAttribute, relatedBy: .equal, toItem: self,
                                                         attribute: lateralSpanAttribute, multiplier: 1, constant: 0)
        addConstraint(selectionOverlayLateral)
        
        let selectionOverlayX = NSLayoutConstraint(item: selectionOverlay, attribute: .centerX, relatedBy: .equal, toItem: self,
                                                   attribute: .centerX, multiplier: 1, constant: 0)
        addConstraint(selectionOverlayX)
        
        let selectionOverlayY = NSLayoutConstraint(item: selectionOverlay, attribute: .centerY, relatedBy: .equal, toItem: self,
                                                   attribute: .centerY, multiplier: 1, constant: 0)
        addConstraint(selectionOverlayY)
    }
    
    private func setupSelectionImageView() {
        selectionImageView.isUserInteractionEnabled = false
        selectionImageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(selectionImageView)
        
        let spanAttribute = scrollingDirection.spanLayoutAttribute()
        selectionImageSpanConstraint = NSLayoutConstraint(item: selectionImageView, attribute: spanAttribute, relatedBy: .equal, toItem: nil,
                                                          attribute: .notAnAttribute, multiplier: 1, constant: itemSpan)
        self.addConstraint(selectionImageSpanConstraint)
        
        let lateralSpanAttribute = scrollingDirection.lateralSpanLayoutAttribute()
        let selectionImageLateralSpan = NSLayoutConstraint(item: selectionImageView, attribute: lateralSpanAttribute, relatedBy: .equal, toItem: self,
                                                           attribute: lateralSpanAttribute, multiplier: 1, constant: 0)
        addConstraint(selectionImageLateralSpan)
        
        let selectionImageX = NSLayoutConstraint(item: selectionImageView, attribute: .centerX, relatedBy: .equal, toItem: self,
                                                 attribute: .centerX, multiplier: 1, constant: 0)
        addConstraint(selectionImageX)
        
        let selectionImageY = NSLayoutConstraint(item: selectionImageView, attribute: .centerY, relatedBy: .equal, toItem: self,
                                                 attribute: .centerY, multiplier: 1, constant: 0)
        addConstraint(selectionImageY)
    }
    
    private func setupSelectionIndicator() {
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectionIndicator)
        
        let spanAttribute = scrollingDirection.spanLayoutAttribute()
        let selectionIndicatorSpan = NSLayoutConstraint(item: selectionIndicator, attribute: spanAttribute, relatedBy: .equal, toItem: nil,
                                                        attribute: .notAnAttribute, multiplier: 1, constant: 2.0)
        addConstraint(selectionIndicatorSpan)
        
        let lateralSpanAttribute = scrollingDirection.lateralSpanLayoutAttribute()
        let selectionIndicatorLateralSpan = NSLayoutConstraint(item: selectionIndicator, attribute: lateralSpanAttribute, relatedBy: .equal,
                                                               toItem: self, attribute: lateralSpanAttribute, multiplier: 1, constant: 0)
        addConstraint(selectionIndicatorLateralSpan)
        
        let edgeAttribute: NSLayoutConstraint.Attribute = scrollingDirection == .horizontal ? .trailing : .bottom
        let spanCenterAttribute: NSLayoutConstraint.Attribute = scrollingDirection == .horizontal ? .centerX : .centerY
        let lateralCenterAttribute: NSLayoutConstraint.Attribute = scrollingDirection == .horizontal ? .centerY : .centerX
        selectionIndicatorEdgeConstraint = NSLayoutConstraint(item: selectionIndicator, attribute: edgeAttribute, relatedBy: .equal,
                                                              toItem: self, attribute: spanCenterAttribute, multiplier: 1, constant: itemSpan / 2)
        addConstraint(selectionIndicatorEdgeConstraint)
        
        let selectionIndicatorCenter = NSLayoutConstraint(item: selectionIndicator, attribute: lateralCenterAttribute, relatedBy: .equal,
                                                          toItem: self, attribute: lateralCenterAttribute, multiplier: 1, constant: 0)
        addConstraint(selectionIndicatorCenter)
    }
    
    // MARK: Infinite Scrolling Helpers
    
    private func generateInfinityItemsMultiplier() -> Int {
        if scrollingStyle == .default {
            return 1
        }
        
        if numberOfItemsByDataSource > 100 {
            return 100
        } else if numberOfItemsByDataSource < 100 && numberOfItemsByDataSource > 50 {
            return 200
        } else if numberOfItemsByDataSource < 50 && numberOfItemsByDataSource > 25 {
            return 400
        } else {
            return 800
        }
    }
    
    // MARK: UI handlers
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if !setupHasBeenDone {
            configureSetup()
            setupHasBeenDone = true
        }
    }
    
    private func adjustSelectionOverlayHeightConstraint() {
        if selectionOverlaySpanConstraint.constant != itemSpan || selectionImageSpanConstraint.constant != itemSpan || selectionIndicatorEdgeConstraint.constant != (itemSpan / 2) {
            selectionOverlaySpanConstraint.constant = itemSpan
            selectionImageSpanConstraint.constant = itemSpan
            selectionIndicatorEdgeConstraint.constant = -(itemSpan / 2)
            layoutIfNeeded()
        }
    }
    
    private func indexForItem(_ item: Int) -> Int {
        return item % (numberOfItemsByDataSource > 0 ? numberOfItemsByDataSource : 1)
    }
    
    // MARK: - Actions
    
    /**
     Selects the nearby to middle item that matches with the provided index.
     
     - parameter item: A valid index provided by Data Source.
     */
    private func selectedNearbyToMiddleItem(_ item: Int) {
        currentSelectedItem = item % numberOfItemsByDataSource
        collectionView.reloadData()
        
        if numberOfItemsByDataSource > 0 && collectionView.numberOfItems(inSection: 0) > 0 {
            let indexOfSelectedItem = visibleIndexOfSelectedItem()
            setContentOffset(CGFloat(indexOfSelectedItem) * itemSpan - endCapSpan, animated: false)
            
            delegate?.occasionPicker?(self, didSelectItem: currentSelectedItem, index: currentSelectedIndex)
        }
    }
    
    private func setContentOffset(_ offset: CGFloat, animated: Bool) {
        var offsetPoint = CGPoint.zero
        switch scrollingDirection {
        case .horizontal:
            offsetPoint.x = offset
        case .vertical:
            offsetPoint.y = offset
        }
        
        if animated {
            isAnimating = true
        }
        
        collectionView.setContentOffset(offsetPoint, animated: animated)
    }
    
    private var itemSpan: CGFloat {
        return delegate?.occasionPickerSpanForItems(self) ?? 0
    }
    
    private var itemLateralSpan: CGFloat {
        return bounds.size.lateralSpan(forDirection: scrollingDirection)
    }
    
    private var endCapSpan: CGFloat {
        return (bounds.size.span(forDirection: scrollingDirection) - itemSpan) * 0.5
    }
    
    /**
     Selects literally the item with index that the user tapped.
     
     - parameter item: The item index that the user tapped, i.e. the Data Source index times the `infinityItemsMultiplier`.
     */
    private func selectTappedItem(_ item: Int) {
        delegate?.occasionPicker?(self, didTapItem: item, index: indexForItem(item))
        selectItem(item, animated: true)
    }
    
    /**
     Configure the first item selection: If some pre-selected item was set, we select it, else we select the nearby to middle at all.
     */
    private func configureFirstSelection() {
        let itemToSelect = currentSelectedItem != nil ? currentSelectedItem : Int(ceil(Float(numberOfItemsByDataSource) / 2.0))
        selectedNearbyToMiddleItem(itemToSelect!)
    }
    
    private func turnOccasionPickerOn() {
        collectionView.isScrollEnabled = true
    }
    
    private func turnOccasionPickerOff() {
        collectionView.isScrollEnabled = false
    }
    
    /**
     This is a private helper that we use to reach the visible index of the current selected item.
     Since we multiply the items several times to create an Infinite Scrolling experience, the index of a visible selected item may
     not be the same as the index provided on Data Source.
     
     - returns: The visible index of current selected item.
     */
    private func visibleIndexOfSelectedItem() -> Int {
        let middleMultiplier = scrollingStyle == .infinite ? (infinityItemsMultiplier / 2) : infinityItemsMultiplier
        let middleIndex = numberOfItemsByDataSource * middleMultiplier
        let indexForSelectedItem: Int
        
        if let _ = currentSelectedItem , scrollingStyle == .default && currentSelectedItem == 0 {
            indexForSelectedItem = 0
        } else if let _ = currentSelectedItem {
            indexForSelectedItem = middleIndex - (numberOfItemsByDataSource - currentSelectedItem)
        } else {
            let middleItem = Int(ceil(Float(numberOfItemsByDataSource) / 2.0))
            indexForSelectedItem = middleIndex - (numberOfItemsByDataSource - middleItem)
        }
        
        return indexForSelectedItem
    }
    
    func selectItem(_ item : Int, animated: Bool) {
        
        var finalItem = item;
        
        if (scrollingStyle == .infinite && item < numberOfItemsByDataSource) {
            let selectedItem = currentSelectedItem ?? Int(ceil(Float(numberOfItemsByDataSource) / 2.0))
            let diff = (item % numberOfItemsByDataSource) - (selectedItem % numberOfItemsByDataSource)
            finalItem = selectedItem + diff
        }
        
        currentSelectedItem = finalItem % numberOfItemsByDataSource
        delegate?.occasionPicker?(self, didSelectItem: currentSelectedItem, index: currentSelectedIndex)
        setContentOffset(CGFloat(finalItem) * itemSpan - endCapSpan, animated: animated)
    }
    
    // MARK: Scrolling Movement
    
    private var isMoving = false
    
    private func trackMovementChanges() {
        let moving = isAnimating || isScrolling
        if moving != isMoving {
            isMoving = moving
            if isMoving {
                delegate?.occasionPickerWillBeginMoving?(self)
            } else {
                delegate?.occasionPickerDidEndMoving?(self)
            }
        }
    }
}

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

