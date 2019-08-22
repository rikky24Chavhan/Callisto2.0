//
//  PickerView.swift
//
//  Created by Filipe Alvarenga on 19/05/15.
//  Copyright (c) 2015 Filipe Alvarenga. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

// MARK: - Protocols

@objc public protocol PickerViewDataSource: class {
    func pickerViewNumberOfItems(_ pickerView: PickerView) -> Int
    func pickerView(_ pickerView: PickerView, titleForItem item: Int, index: Int) -> String
}

@objc public protocol PickerViewDelegate: class {
    func pickerViewSpanForItems(_ pickerView: PickerView) -> CGFloat
    @objc optional func pickerView(_ pickerView: PickerView, didSelectItem item: Int, index: Int)
    @objc optional func pickerView(_ pickerView: PickerView, didTapItem item: Int, index: Int)
    @objc optional func pickerView(_ pickerView: PickerView, styleForLabel label: UILabel, highlighted: Bool)
    @objc optional func pickerView(_ pickerView: PickerView, viewForItem item: Int, index: Int, highlighted: Bool, reusingView view: UIView?) -> UIView?

    @objc optional func pickerViewWillBeginMoving(_ pickerView: PickerView)
    @objc optional func pickerViewDidEndMoving(_ pickerView: PickerView)
}

open class PickerView: UIView {

    // MARK: Nested Types

    fileprivate class SimplePickerCollectionViewCell: UICollectionViewCell {
        lazy var titleLabel: UILabel = {
            let titleLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: self.contentView.frame.width, height: self.contentView.frame.height))
            titleLabel.textAlignment = .center

            return titleLabel
        }()

        var customView: UIView? {
            willSet {
                if customView != newValue {
                    customView?.removeFromSuperview()
                }
            }
            didSet {
                if let newCustomView = customView {
                    contentView.addSubview(newCustomView)

                    newCustomView.translatesAutoresizingMaskIntoConstraints = false
                    for format in [ "H:|[customView]|", "V:|[customView]|" ] {
                        contentView.addConstraints(NSLayoutConstraint.constraints(
                            withVisualFormat: format,
                            options: [],
                            metrics: nil,
                            views: ["customView" : newCustomView]
                        ))
                    }
                }
            }
        }
    }

    /**
        ScrollingStyle Enum.

        - parameter Default: Show only the number of rows informed in data source.

        - parameter Infinite: Loop through the data source offering a infinite scrolling experience to the user.
    */

    @objc public enum ScrollingStyle: Int {
        case `default`, infinite
    }

    @objc public enum ScrollingDirection: Int {
        case horizontal
        case vertical

        func opposite() -> ScrollingDirection {
            return self == .horizontal ? .vertical : .horizontal
        }

        fileprivate func collectionViewScrollDirection() -> UICollectionViewScrollDirection {
            return self == .horizontal ? .horizontal : .vertical
        }

        fileprivate func spanLayoutAttribute() -> NSLayoutAttribute {
            return self == .horizontal ? .width : .height
        }

        fileprivate func lateralSpanLayoutAttribute() -> NSLayoutAttribute {
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

    @objc public enum SelectionStyle: Int {
        case none, defaultIndicator, overlay, image
    }

    // MARK: Properties

    var enabled = true {
        didSet {
            if enabled {
                turnPickerViewOn()
            } else {
                turnPickerViewOff()
            }
        }
    }

    fileprivate var selectionOverlaySpanConstraint: NSLayoutConstraint!
    fileprivate var selectionImageSpanConstraint: NSLayoutConstraint!
    fileprivate var selectionIndicatorEdgeConstraint: NSLayoutConstraint!
    fileprivate var pickerCellBackgroundColor: UIColor?

    var numberOfItemsByDataSource: Int {
        get {
            return dataSource?.pickerViewNumberOfItems(self) ?? 0
        }
    }

    fileprivate let pickerViewCellIdentifier = "pickerViewCell"

    open weak var dataSource: PickerViewDataSource?
    open weak var delegate: PickerViewDelegate? {
        didSet {
            updateInsets()
        }
    }

    open override var bounds: CGRect {
        didSet {
            updateInsets()
        }
    }

    open lazy var defaultSelectionIndicator: UIView = {
        let selectionIndicator = UIView()
        selectionIndicator.backgroundColor = self.tintColor
        selectionIndicator.alpha = 0.0

        return selectionIndicator
    }()

    open lazy var selectionOverlay: UIView = {
        let selectionOverlay = UIView()
        selectionOverlay.backgroundColor = self.tintColor
        selectionOverlay.alpha = 0.0

        return selectionOverlay
    }()

    open lazy var selectionImageView: UIImageView = {
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

    fileprivate var infinityItemsMultiplier: Int = 1
    open var currentSelectedItem: Int!
    open var currentSelectedIndex: Int {
        get {
            return indexForItem(currentSelectedItem)
        }
    }

    fileprivate var firstTimeOrientationChanged = true
    fileprivate var orientationChanged = false

    fileprivate var isScrolling = false {
        didSet {
            trackMovementChanges()
        }
    }

    fileprivate var isAnimating = false {
        didSet {
            trackMovementChanges()
        }
    }

    fileprivate var setupHasBeenDone = false

    open var scrollingStyle = ScrollingStyle.default {
        didSet {
            switch scrollingStyle {
            case .default:
                infinityItemsMultiplier = 1
            case .infinite:
                infinityItemsMultiplier = generateInfinityItemsMultiplier()
            }
        }
    }

    open var scrollingDirection = ScrollingDirection.vertical {
        didSet {
            if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.scrollDirection = scrollingDirection.collectionViewScrollDirection()
            }
        }
    }

    open var selectionStyle = SelectionStyle.none {
        didSet {
            switch selectionStyle {
            case .defaultIndicator:
                defaultSelectionIndicator.alpha = 1.0
                selectionOverlay.alpha = 0.0
                selectionImageView.alpha = 0.0
            case .overlay:
                selectionOverlay.alpha = 0.25
                defaultSelectionIndicator.alpha = 0.0
                selectionImageView.alpha = 0.0
            case .image:
                selectionImageView.alpha = 1.0
                selectionOverlay.alpha = 0.0
                defaultSelectionIndicator.alpha = 0.0
            case .none:
                selectionOverlay.alpha = 0.0
                defaultSelectionIndicator.alpha = 0.0
                selectionImageView.alpha = 0.0
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

    fileprivate func setup() {
        infinityItemsMultiplier = generateInfinityItemsMultiplier()

        // Setup subviews constraints and apperance
        translatesAutoresizingMaskIntoConstraints = false
        setupCollectionView()

        setupSelectionOverlay()
        setupSelectionImageView()
        setupDefaultSelectionIndicator()

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        self.collectionView.reloadData()

        // This needs to be done after a delay - I am guessing it basically needs to be called once
        // the view is already displaying
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            // Some UI Adjustments we need to do after setting UICollectionView data source & delegate.
            self.configureFirstSelection()
            self.adjustSelectionOverlayHeightConstraint()
        }
    }

    fileprivate func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.scrollsToTop = false
        collectionView.register(SimplePickerCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: self.pickerViewCellIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)

        let collectionViewH = NSLayoutConstraint(item: collectionView, attribute: .height, relatedBy: .equal, toItem: self,
                                                attribute: .height, multiplier: 1, constant: 0)
        addConstraint(collectionViewH)

        let collectionViewW = NSLayoutConstraint(item: collectionView, attribute: .width, relatedBy: .equal, toItem: self,
                                                attribute: .width, multiplier: 1, constant: 0)
        addConstraint(collectionViewW)

        let collectionViewL = NSLayoutConstraint(item: collectionView, attribute: .leading, relatedBy: .equal, toItem: self,
                                                attribute: .leading, multiplier: 1, constant: 0)
        addConstraint(collectionViewL)

        let collectionViewTop = NSLayoutConstraint(item: collectionView, attribute: .top, relatedBy: .equal, toItem: self,
                                                attribute: .top, multiplier: 1, constant: 0)
        addConstraint(collectionViewTop)

        let collectionViewBottom = NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: self,
                                                    attribute: .bottom, multiplier: 1, constant: 0)
        addConstraint(collectionViewBottom)

        let collectionViewT = NSLayoutConstraint(item: collectionView, attribute: .trailing, relatedBy: .equal, toItem: self,
                                                attribute: .trailing, multiplier: 1, constant: 0)
        addConstraint(collectionViewT)
    }

    fileprivate func setupSelectionOverlay() {
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

    fileprivate func setupSelectionImageView() {
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

    fileprivate func setupDefaultSelectionIndicator() {
        defaultSelectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(defaultSelectionIndicator)

        let spanAttribute = scrollingDirection.spanLayoutAttribute()
        let selectionIndicatorSpan = NSLayoutConstraint(item: defaultSelectionIndicator, attribute: spanAttribute, relatedBy: .equal, toItem: nil,
                                                        attribute: .notAnAttribute, multiplier: 1, constant: 2.0)
        addConstraint(selectionIndicatorSpan)

        let lateralSpanAttribute = scrollingDirection.lateralSpanLayoutAttribute()
        let selectionIndicatorLateralSpan = NSLayoutConstraint(item: defaultSelectionIndicator, attribute: lateralSpanAttribute, relatedBy: .equal,
                                                        toItem: self, attribute: lateralSpanAttribute, multiplier: 1, constant: 0)
        addConstraint(selectionIndicatorLateralSpan)

        let edgeAttribute: NSLayoutAttribute = scrollingDirection == .horizontal ? .trailing : .bottom
        let spanCenterAttribute: NSLayoutAttribute = scrollingDirection == .horizontal ? .centerX : .centerY
        let lateralCenterAttribute: NSLayoutAttribute = scrollingDirection == .horizontal ? .centerY : .centerX

        selectionIndicatorEdgeConstraint = NSLayoutConstraint(item: defaultSelectionIndicator, attribute: edgeAttribute, relatedBy: .equal,
                                                              toItem: self, attribute: spanCenterAttribute, multiplier: 1, constant: itemSpan / 2)
        addConstraint(selectionIndicatorEdgeConstraint)

        let selectionIndicatorC = NSLayoutConstraint(item: defaultSelectionIndicator, attribute: lateralCenterAttribute, relatedBy: .equal,
                                                     toItem: self, attribute: lateralCenterAttribute, multiplier: 1, constant: 0)
        addConstraint(selectionIndicatorC)
    }

    fileprivate func updateInsets() {
        if scrollingDirection == .horizontal {
            collectionView.contentInset = UIEdgeInsets(top: 0, left: endCapSpan, bottom: 0, right: endCapSpan)
        } else {
            collectionView.contentInset = UIEdgeInsets(top: endCapSpan, left: 0, bottom: endCapSpan, right: 0)
        }
    }

    // MARK: Infinite Scrolling Helpers

    fileprivate func generateInfinityItemsMultiplier() -> Int {
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

    // MARK: Life Cycle

    open override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        if let _ = newWindow {
            NotificationCenter.default.addObserver(self, selector: #selector(PickerView.adjustCurrentSelectedAfterOrientationChanges),
                                                            name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        } else {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        if !setupHasBeenDone {
            setup()
            setupHasBeenDone = true
        }
    }

    fileprivate func adjustSelectionOverlayHeightConstraint() {
        if selectionOverlaySpanConstraint.constant != itemSpan || selectionImageSpanConstraint.constant != itemSpan || selectionIndicatorEdgeConstraint.constant != (itemSpan / 2) {
            selectionOverlaySpanConstraint.constant = itemSpan
            selectionImageSpanConstraint.constant = itemSpan
            selectionIndicatorEdgeConstraint.constant = -(itemSpan / 2)
            layoutIfNeeded()
        }
    }

    @objc func adjustCurrentSelectedAfterOrientationChanges() {
        setNeedsLayout()
        layoutIfNeeded()

        // Configure the PickerView to select the middle row when the orientation changes during scroll
        if isScrolling {
            let middleItem = Int(ceil(Float(numberOfItemsByDataSource) / 2.0))
            selectedNearbyToMiddleItem(middleItem)
        } else {
            let itemToSelect = currentSelectedItem != nil ? currentSelectedItem : Int(ceil(Float(numberOfItemsByDataSource) / 2.0))
            selectedNearbyToMiddleItem(itemToSelect!)
        }

        if firstTimeOrientationChanged {
            firstTimeOrientationChanged = false
            return
        }

        if !isScrolling {
            return
        }

        orientationChanged = true
    }

    fileprivate func indexForItem(_ item: Int) -> Int {
        return item % (numberOfItemsByDataSource > 0 ? numberOfItemsByDataSource : 1)
    }

    // MARK: - Actions

    /**
        Selects the nearby to middle row that matches with the provided index.

        - parameter row: A valid index provided by Data Source.
    */
    fileprivate func selectedNearbyToMiddleItem(_ item: Int) {
        currentSelectedItem = item % numberOfItemsByDataSource
        collectionView.reloadData()

        if numberOfItemsByDataSource > 0 && collectionView.numberOfItems(inSection: 0) > 0 {
            let indexOfSelectedItem = visibleIndexOfSelectedItem()
            setContentOffset(CGFloat(indexOfSelectedItem) * itemSpan - endCapSpan, animated: false)

            delegate?.pickerView?(self, didSelectItem: currentSelectedItem, index: currentSelectedIndex)
        }
    }

    fileprivate func setContentOffset(_ offset: CGFloat, animated: Bool) {
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

    fileprivate var itemSpan: CGFloat {
        return delegate?.pickerViewSpanForItems(self) ?? 0
    }

    fileprivate var itemLateralSpan: CGFloat {
        return bounds.size.lateralSpan(forDirection: scrollingDirection)
    }

    fileprivate var endCapSpan: CGFloat {
        return (bounds.size.span(forDirection: scrollingDirection) - itemSpan) * 0.5
    }

    /**
        Selects literally the row with index that the user tapped.

        - parameter row: The row index that the user tapped, i.e. the Data Source index times the `infinityItemsMultiplier`.
    */
    fileprivate func selectTappedItem(_ item: Int) {
        delegate?.pickerView?(self, didTapItem: item, index: indexForItem(item))
        selectItem(item, animated: true)
    }

    /**
        Configure the first row selection: If some pre-selected row was set, we select it, else we select the nearby to middle at all.
    */
    fileprivate func configureFirstSelection() {
        let itemToSelect = currentSelectedItem != nil ? currentSelectedItem : Int(ceil(Float(numberOfItemsByDataSource) / 2.0))
        selectedNearbyToMiddleItem(itemToSelect!)
    }

    fileprivate func turnPickerViewOn() {
        collectionView.isScrollEnabled = true
    }

    fileprivate func turnPickerViewOff() {
        collectionView.isScrollEnabled = false
    }

    /**
        This is an private helper that we use to reach the visible index of the current selected row.
        Because of we multiply the rows several times to create an Infinite Scrolling experience, the index of a visible selected row may
        not be the same as the index provided on Data Source.

        - returns: The visible index of current selected row.
    */
    fileprivate func visibleIndexOfSelectedItem() -> Int {
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

    open func selectItem(_ item : Int, animated: Bool) {

        var finalItem = item;

        if (scrollingStyle == .infinite && item < numberOfItemsByDataSource) {
            let selectedItem = currentSelectedItem ?? Int(ceil(Float(numberOfItemsByDataSource) / 2.0))
            let diff = (item % numberOfItemsByDataSource) - (selectedItem % numberOfItemsByDataSource)
            finalItem = selectedItem + diff
        }

        currentSelectedItem = finalItem % numberOfItemsByDataSource

        delegate?.pickerView?(self, didSelectItem: currentSelectedItem, index: currentSelectedIndex)

        setContentOffset(CGFloat(finalItem) * itemSpan - endCapSpan, animated: animated)
    }

    // MARK: Moving

    private var isMoving = false

    private func trackMovementChanges() {
        let moving = isAnimating || isScrolling
        if moving != isMoving {
            isMoving = moving
            if isMoving {
                delegate?.pickerViewWillBeginMoving?(self)
            } else {
                delegate?.pickerViewDidEndMoving?(self)
            }
        }
    }
}

extension PickerView: UICollectionViewDataSource {

    // MARK: UICollectionViewDataSource

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItemsByDataSource * infinityItemsMultiplier
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let indexOfSelectedItem = visibleIndexOfSelectedItem()

        let pickerViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: pickerViewCellIdentifier, for: indexPath) as! SimplePickerCollectionViewCell

        let view = delegate?.pickerView?(self, viewForItem: indexPath.item, index: indexForItem(indexPath.item), highlighted: indexPath.item == indexOfSelectedItem, reusingView: pickerViewCell.customView)

        pickerViewCell.backgroundColor = pickerCellBackgroundColor ?? UIColor.clear

        if let customView = view {
            pickerViewCell.customView = customView
        } else {
            let size = CGSize(span: itemSpan, lateralSpan: itemLateralSpan, direction: scrollingDirection)
            pickerViewCell.titleLabel.frame = CGRect(origin: .zero, size: size)

            pickerViewCell.contentView.addSubview(pickerViewCell.titleLabel)
            pickerViewCell.titleLabel.backgroundColor = UIColor.clear
            pickerViewCell.titleLabel.text = dataSource?.pickerView(self, titleForItem: indexPath.item, index: indexForItem(indexPath.item))

            delegate?.pickerView?(self, styleForLabel: pickerViewCell.titleLabel, highlighted: indexPath.item == indexOfSelectedItem)
        }

        return pickerViewCell
    }
}

fileprivate extension CGPoint {
    init (offset: CGFloat, lateralOffset: CGFloat = 0, direction: PickerView.ScrollingDirection) {
        let x = direction == .horizontal ? offset : lateralOffset
        let y = direction == .vertical ? offset : lateralOffset
        self.init(x: x, y: y)
    }

    func offset(forDirection direction: PickerView.ScrollingDirection) -> CGFloat {
        return direction == .horizontal ? x : y
    }

    mutating func setOffset(_ offset: CGFloat, forDirection direction: PickerView.ScrollingDirection) {
        switch direction {
        case .horizontal:
            x = offset
            break
        case .vertical:
            y = offset
            break
        }
    }
}

fileprivate extension CGSize {
    init(span: CGFloat, lateralSpan: CGFloat = 0, direction: PickerView.ScrollingDirection) {
        let width = direction == .horizontal ? span : lateralSpan
        let height = direction == .vertical ? span : lateralSpan
        self.init(width: width, height: height)
    }

    func span(forDirection direction: PickerView.ScrollingDirection) -> CGFloat {
        return direction == .horizontal ? width : height
    }

    func lateralSpan(forDirection direction: PickerView.ScrollingDirection) -> CGFloat {
        return span(forDirection: direction.opposite())
    }
}

extension PickerView: UICollectionViewDelegate {

    // MARK: UITableViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectTappedItem(indexPath.item)
    }
}

extension PickerView: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let lateralSpan = bounds.size.lateralSpan(forDirection: scrollingDirection)
        return CGSize(span: itemSpan, lateralSpan: lateralSpan, direction: scrollingDirection)
    }
}

extension PickerView: UIScrollViewDelegate {

    // MARK: UIScrollViewDelegate

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let partialItem = Float((targetContentOffset.pointee.offset(forDirection: scrollingDirection) + endCapSpan) / itemSpan) // Get the estimative of what row will be the selected when the scroll animation ends.
        var roundedItem = Int(lroundf(partialItem)) // Round the estimative to a row

        if roundedItem < 0 {
            roundedItem = 0
        }

        targetContentOffset.pointee.setOffset(CGFloat(roundedItem) * itemSpan - endCapSpan, forDirection: scrollingDirection) // Set the targetContentOffset (where the scrolling position will be when the animation ends) to a rounded value.

        // Update the currentSelectedItem and notify the delegate that we have a new selected row.
        currentSelectedItem = roundedItem % numberOfItemsByDataSource

        delegate?.pickerView?(self, didSelectItem: currentSelectedItem, index: currentSelectedIndex)
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
            if let cellToUnhighlight = collectionView.cellForItem(at: indexPath) as? SimplePickerCollectionViewCell , indexPath.item != roundedItem {
                _ = delegate?.pickerView?(self, viewForItem: indexPath.item, index: indexForItem(indexPath.item), highlighted: false, reusingView: cellToUnhighlight.customView)
                delegate?.pickerView?(self, styleForLabel: cellToUnhighlight.titleLabel, highlighted: false)
            }
        }

        // Highlight the current selected cell during scroll
        if let cellToHighlight = collectionView.cellForItem(at: IndexPath(item: roundedItem, section: 0)) as? SimplePickerCollectionViewCell {
            _ = delegate?.pickerView?(self, viewForItem: roundedItem, index: indexForItem(roundedItem), highlighted: true, reusingView: cellToHighlight.customView)
            delegate?.pickerView?(self, styleForLabel: cellToHighlight.titleLabel, highlighted: true)
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isAnimating = false
    }
}
