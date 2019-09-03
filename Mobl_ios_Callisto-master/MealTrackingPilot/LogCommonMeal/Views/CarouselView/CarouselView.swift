//
//  CarouselView.swift
//  CarouselView
//
//  Created by Rikky Chavhan on 20/08/19.
//  Copyright © 2019 L&T. All rights reserved.
//

import UIKit

@objc protocol CarouselViewDataSource: class {
    func carouselViewNumberOfItems(_ pickerView: CarouselView) -> Int
    func carouselView(_ carouselView: CarouselView, titleForItem item: Int, index: Int) -> String
}

@objc protocol CarouselViewDelegate: class {
    func carouselViewSpanForItems(_ carouselView: CarouselView) -> CGFloat
    func carouselView(_ carouselView: CarouselView, didSelectItem item: Int, index: Int)
    func carouselView(_ carouselView: CarouselView, viewForItem item: Int, index: Int, highlighted: Bool, reusingView view: UIView?) -> UIView?
}

class CarouselView: UIView {
    
    // MARK: Private Properties
    
    private var selectionOverlaySpanConstraint: NSLayoutConstraint!
    private var selectionImageSpanConstraint: NSLayoutConstraint!
    private var selectionIndicatorEdgeConstraint: NSLayoutConstraint!
    private var setupHasBeenDone = false
    private var isMoving = false
    
    // MARK: Public Stored Properties
    
    var pickerCellBackgroundColor: UIColor?
    var infinityItemsMultiplier = 1
    var currentSelectedItem: Int!
    var orientationChanged = false
    
    weak var dataSource: CarouselViewDataSource?
    weak var delegate: CarouselViewDelegate? {
        didSet {
            updateInsets()
        }
    }
    
    /*
    var enabled = true {
        didSet {
            enabled ? turnPickerViewOn() : turnPickerViewOff()
        }
    }
     */
    
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
    
    var itemSpan: CGFloat {
        return delegate?.carouselViewSpanForItems(self) ?? 0
    }
    
    var itemLateralSpan: CGFloat {
        return bounds.size.lateralSpan(forDirection: scrollingDirection)
    }
    
    var endCapSpan: CGFloat {
        return (bounds.size.span(forDirection: scrollingDirection) - itemSpan) * 0.5
    }
    
    
    // MARK: Public Computed Properties
    
    var numberOfItemsByDataSource: Int {
        get {
            return dataSource?.carouselViewNumberOfItems(self) ?? 0
        }
    }
    
    var currentSelectedIndex: Int {
        get {
            return indexForItem(currentSelectedItem)
        }
    }
    
    // MARK: Public Lazy Properties
    
    lazy var defaultSelectionIndicator: UIView = {
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
    
    
    // MARK: Life Cycle
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        if !setupHasBeenDone {
            setup()
            setupHasBeenDone = true
        }
    }
    
    // MARK: Private Methods
    
    private func setup() {
        infinityItemsMultiplier = generateInfinityItemsMultiplier()
        
        // Setup subviews constraints and apperance
        translatesAutoresizingMaskIntoConstraints = false
        setupCollectionView()
        setupSelectionOverlay()
        setupSelectionImageView()
        setupDefaultSelectionIndicator()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.reloadData()
        
        // This needs to be done after a delay - I am guessing it basically needs to be called once
        // the view is already displaying
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            // Some UI Adjustments we need to do after setting UICollectionView data source & delegate.
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
        collectionView.register(CarouselCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: CarouselViewConstants.carouselViewCellIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        
        let collectionViewH = NSLayoutConstraint(item: collectionView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0)
        addConstraint(collectionViewH)
        let collectionViewW = NSLayoutConstraint(item: collectionView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0)
        addConstraint(collectionViewW)
        let collectionViewL = NSLayoutConstraint(item: collectionView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
        addConstraint(collectionViewL)
        let collectionViewTop = NSLayoutConstraint(item: collectionView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        addConstraint(collectionViewTop)
        let collectionViewBottom = NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        addConstraint(collectionViewBottom)
        let collectionViewT = NSLayoutConstraint(item: collectionView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        addConstraint(collectionViewT)
    }
    
    private func setupSelectionOverlay() {
        selectionOverlay.isUserInteractionEnabled = false
        selectionOverlay.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectionOverlay)
        
        let spanAttribute = scrollingDirection.spanLayoutAttribute()
        selectionOverlaySpanConstraint = NSLayoutConstraint(item: selectionOverlay, attribute: spanAttribute, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: itemSpan)
        addConstraint(selectionOverlaySpanConstraint)
        let lateralSpanAttribute = scrollingDirection.lateralSpanLayoutAttribute()
        let selectionOverlayLateral = NSLayoutConstraint(item: selectionOverlay, attribute: lateralSpanAttribute, relatedBy: .equal, toItem: self, attribute: lateralSpanAttribute, multiplier: 1, constant: 0)
        addConstraint(selectionOverlayLateral)
        let selectionOverlayX = NSLayoutConstraint(item: selectionOverlay, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        addConstraint(selectionOverlayX)
        let selectionOverlayY = NSLayoutConstraint(item: selectionOverlay, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        addConstraint(selectionOverlayY)
    }
    
    private func setupSelectionImageView() {
        selectionImageView.isUserInteractionEnabled = false
        selectionImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectionImageView)
        
        let spanAttribute = scrollingDirection.spanLayoutAttribute()
        selectionImageSpanConstraint = NSLayoutConstraint(item: selectionImageView, attribute: spanAttribute, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: itemSpan)
        addConstraint(selectionImageSpanConstraint)
        let lateralSpanAttribute = scrollingDirection.lateralSpanLayoutAttribute()
        let selectionImageLateralSpan = NSLayoutConstraint(item: selectionImageView, attribute: lateralSpanAttribute, relatedBy: .equal, toItem: self, attribute: lateralSpanAttribute, multiplier: 1, constant: 0)
        addConstraint(selectionImageLateralSpan)
        let selectionImageX = NSLayoutConstraint(item: selectionImageView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        addConstraint(selectionImageX)
        let selectionImageY = NSLayoutConstraint(item: selectionImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        addConstraint(selectionImageY)
    }
    
    private func setupDefaultSelectionIndicator() {
        defaultSelectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(defaultSelectionIndicator)
        
        let spanAttribute = scrollingDirection.spanLayoutAttribute()
        let selectionIndicatorSpan = NSLayoutConstraint(item: defaultSelectionIndicator, attribute: spanAttribute, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 2.0)
        addConstraint(selectionIndicatorSpan)
        let lateralSpanAttribute = scrollingDirection.lateralSpanLayoutAttribute()
        let selectionIndicatorLateralSpan = NSLayoutConstraint(item: defaultSelectionIndicator, attribute: lateralSpanAttribute, relatedBy: .equal, toItem: self, attribute: lateralSpanAttribute, multiplier: 1, constant: 0)
        addConstraint(selectionIndicatorLateralSpan)
        let edgeAttribute: NSLayoutConstraint.Attribute = scrollingDirection == .horizontal ? .trailing : .bottom
        let spanCenterAttribute: NSLayoutConstraint.Attribute = scrollingDirection == .horizontal ? .centerX : .centerY
        let lateralCenterAttribute: NSLayoutConstraint.Attribute = scrollingDirection == .horizontal ? .centerY : .centerX
        selectionIndicatorEdgeConstraint = NSLayoutConstraint(item: defaultSelectionIndicator, attribute: edgeAttribute, relatedBy: .equal, toItem: self, attribute: spanCenterAttribute, multiplier: 1, constant: itemSpan / 2)
        addConstraint(selectionIndicatorEdgeConstraint)
        let selectionIndicatorC = NSLayoutConstraint(item: defaultSelectionIndicator, attribute: lateralCenterAttribute, relatedBy: .equal, toItem: self, attribute: lateralCenterAttribute, multiplier: 1, constant: 0)
        addConstraint(selectionIndicatorC)
    }
    
    private func updateInsets() {
        if scrollingDirection == .horizontal {
            collectionView.contentInset = UIEdgeInsets(top: 0, left: endCapSpan, bottom: 0, right: endCapSpan)
        } else {
            collectionView.contentInset = UIEdgeInsets(top: endCapSpan, left: 0, bottom: endCapSpan, right: 0)
        }
    }
    
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
    
    private func adjustSelectionOverlayHeightConstraint() {
        if selectionOverlaySpanConstraint.constant != itemSpan || selectionImageSpanConstraint.constant != itemSpan || selectionIndicatorEdgeConstraint.constant != (itemSpan / 2) {
            selectionOverlaySpanConstraint.constant = itemSpan
            selectionImageSpanConstraint.constant = itemSpan
            selectionIndicatorEdgeConstraint.constant = -(itemSpan / 2)
            layoutIfNeeded()
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
    
    private func trackMovementChanges() {
        let moving = isAnimating || isScrolling
        if moving != isMoving {
            isMoving = moving
        }
    }
    
    /**
     Configure the first row selection: If some pre-selected row was set, we select it, else we select the nearby to middle at all.
     */
    private func configureFirstSelection() {
        let itemToSelect = currentSelectedItem != nil ? currentSelectedItem : Int(ceil(Float(numberOfItemsByDataSource) / 2.0))
        selectedNearbyToMiddleItem(itemToSelect!)
    }
    
    // MARK: - Public Methods
    
    func indexForItem(_ item: Int) -> Int {
        return item % (numberOfItemsByDataSource > 0 ? numberOfItemsByDataSource : 1)
    }
    
    /**
     Selects the nearby to middle row that matches with the provided index.
     - parameter row: A valid index provided by Data Source.
     */
    func selectedNearbyToMiddleItem(_ item: Int) {
        currentSelectedItem = item % numberOfItemsByDataSource
        collectionView.reloadData()
        if numberOfItemsByDataSource > 0 && collectionView.numberOfItems(inSection: 0) > 0 {
            let indexOfSelectedItem = visibleIndexOfSelectedItem()
            setContentOffset(CGFloat(indexOfSelectedItem) * itemSpan - endCapSpan, animated: false)
            delegate?.carouselView(self, didSelectItem: currentSelectedItem, index: currentSelectedIndex)
        }
    }
    
    /**
     Selects literally the row with index that the user tapped.
     - parameter row: The row index that the user tapped, i.e. the Data Source index times the `infinityItemsMultiplier`.
     */
    func selectTappedItem(_ item: Int) {
        selectItem(item, animated: true)
    }
    
    /**
     This is an private helper that we use to reach the visible index of the current selected row.
     Because of we multiply the rows several times to create an Infinite Scrolling experience, the index of a visible selected row may
     not be the same as the index provided on Data Source.
     - returns: The visible index of current selected row.
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
        var finalItem = item
        if (scrollingStyle == .infinite && item < numberOfItemsByDataSource) {
            let selectedItem = currentSelectedItem ?? Int(ceil(Float(numberOfItemsByDataSource) / 2.0))
            let diff = (item % numberOfItemsByDataSource) - (selectedItem % numberOfItemsByDataSource)
            finalItem = selectedItem + diff
        }
        currentSelectedItem = finalItem % numberOfItemsByDataSource
        delegate?.carouselView(self, didSelectItem: currentSelectedItem, index: currentSelectedIndex)
        setContentOffset(CGFloat(finalItem) * itemSpan - endCapSpan, animated: animated)
    }
    
    
    
    
}
