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

    // MARK: OccasionPicker Properties
    
    let occasionPickerCellIdentifier = "occasionPickerCell"
    
    weak var dataSource: OccasionPickerDataSource?
    weak var delegate: OccasionPickerDelegate?
    
    var enabled = true {
        didSet {
            if enabled {
                turnOccasionPickerOn()
            } else {
                turnOccasionPickerOff()
            }
        }
    }
    
    var numberOfItemsByDataSource: Int {
        get {
            return dataSource?.occasionPickerNumberOfItems(self) ?? 0
        }
    }

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
    
    var infinityItemsMultiplier: Int = 1
    private var setupHasBeenDone = false
    
    var isScrolling = false {
        didSet {
            trackMovementChanges()
        }
    }
    
    var isAnimating = false {
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
    
    private var isMoving = false
    
    var itemSpan: CGFloat {
        return delegate?.occasionPickerSpanForItems(self) ?? 0
    }
    
    var itemLateralSpan: CGFloat {
        return bounds.size.lateralSpan(forDirection: scrollingDirection)
    }
    
    var endCapSpan: CGFloat {
        return (bounds.size.span(forDirection: scrollingDirection) - itemSpan) * 0.5
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
        
        collectionView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        collectionView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    private func setupSelectionOverlay() {
        selectionOverlay.isUserInteractionEnabled = false
        selectionOverlay.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(selectionOverlay)
        
        selectionOverlay.widthAnchor.constraint(equalToConstant: itemSpan).isActive = true
        selectionOverlay.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        selectionOverlay.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        selectionOverlay.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
    
    private func setupSelectionImageView() {
        selectionImageView.isUserInteractionEnabled = false
        selectionImageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(selectionImageView)
        
        selectionImageView.widthAnchor.constraint(equalToConstant: itemSpan).isActive = true
        selectionImageView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        selectionImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        selectionImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
    
    private func setupSelectionIndicator() {
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectionIndicator)
        
        selectionIndicator.widthAnchor.constraint(equalToConstant: 2.0).isActive = true
        selectionIndicator.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        selectionIndicator.trailingAnchor.constraint(equalTo: self.centerXAnchor, constant:itemSpan/2).isActive = true
        selectionIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
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
    
    func indexForItem(_ item: Int) -> Int {
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
    
    /**
     Selects literally the item with index that the user tapped.
     - parameter item: The item index that the user tapped, i.e. the Data Source index times the `infinityItemsMultiplier`.
     */
    func selectTappedItem(_ item: Int) {
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
     This is a private helper that we use to reach the visible index of the current selected item. Since we multiply the items several times to create an infinite scrolling experience, the index of a visible selected item may not be the same as the index provided on Data Source.
     - returns: The visible index of current selected item.
     */
    func visibleIndexOfSelectedItem() -> Int {
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

