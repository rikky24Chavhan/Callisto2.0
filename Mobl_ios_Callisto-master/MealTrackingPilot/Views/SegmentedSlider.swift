//
//  SegmentedSlider.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/17/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

public protocol SegmentedSliderDelegate: class {
    func segmentedSlider(_ segmentedSlider: SegmentedSlider, canSelectSegment index: Int) -> Bool
}

public final class SegmentedSlider: UIControl {

    private struct Constants {
        static let minimumTouchableDimension: CGFloat = 44.0
    }

    public weak var delegate: SegmentedSliderDelegate?

    public var items: [String] {
        didSet {
            refreshSegmentLabels()
            selectItem(at: 0)   // Configure text for selected segment
        }
    }

    public var attributedItems: [NSAttributedString]? {
        didSet {
            items = attributedItems?.map { $0.string } ?? []
        }
    }

    public var segmentLayoutInverted: Bool = false {
        didSet {
            refreshSegmentLabels()
            refreshSelectedSegmentXConstraint(animated: false)
        }
    }

    private(set) var selectedSegmentIndex: Int = -1

    public let backgroundSegmentView = UIView()
    public let selectedSegmentView = UIView()

    public var backgroundSegmentInset: CGFloat = 2.0 {
        didSet {
            refreshBackgroundSegmentInsets()
            layoutIfNeeded()
        }
    }
    private var backgroundSegmentInsetConstraints: [NSLayoutConstraint]?

    private let selectedSegmentLabel = UILabel()
    private var selectedSegmentWidthConstraint: NSLayoutConstraint!
    private var selectedSegmentCenterXConstraint: NSLayoutConstraint!

    private var segmentLabels: [UILabel] = []
    private var segmentLabelXConstraints: [NSLayoutConstraint] = []
    public var segmentLabelTextColor: UIColor = UIColor.black {
        didSet {
            refreshSegmentLabels()
        }
    }
    public var segmentLabelFont: UIFont = UIFont.systemFont(ofSize: 16.0) {
        didSet {
            refreshSegmentLabels()
        }
    }

    public var selectedSegmentLabelTextColor: UIColor? {
        didSet {
            refreshSegmentLabels()
        }
    }
    public var selectedSegmentLabelFont: UIFont? {
        didSet {
            refreshSegmentLabels()
        }
    }

    // MARK: - Lifecycle

    public init(items: [String]) {
        self.items = items
        super.init(frame: .zero)
        setup()
    }

    public init(attributedItems: [NSAttributedString]) {
        self.items = []
        self.attributedItems = attributedItems  // This will set items appropriately
        super.init(frame: .zero)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        items = []
        super.init(coder: aDecoder)
        setup()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        if items.count > 0 {
            let longerDimension = max(frame.width, frame.height)
            selectedSegmentWidthConstraint.constant = longerDimension / CGFloat(items.count)
            refreshSelectedSegmentXConstraint(animated: false)

            for (index, constraint) in segmentLabelXConstraints.enumerated() {
                let segmentWidth = selectedSegmentWidthConstraint.constant
                let segmentCenterOffset = segmentWidth / 2
                var offset = CGFloat(index) * segmentWidth + segmentCenterOffset
                if segmentLayoutInverted {
                    offset = longerDimension - offset
                }
                constraint.constant = -offset
            }
        }
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = UIColor.clear

        // Background Segment View
        backgroundSegmentView.frame = bounds
        backgroundSegmentView.layer.masksToBounds = true
        addSubview(backgroundSegmentView)
        refreshBackgroundSegmentInsets()

        // Selected segment View
        selectedSegmentView.layer.masksToBounds = true
        addSubview(selectedSegmentView)
        _ = constrainView(toTop: selectedSegmentView)
        _ = constrainView(toBottom: selectedSegmentView)
        selectedSegmentWidthConstraint = constrainView(selectedSegmentView, toWidth: 0)
        selectedSegmentCenterXConstraint = constrainView(toMiddleHorizontally: selectedSegmentView)

        // Selected Segment Label
        selectedSegmentLabel.backgroundColor = UIColor.clear
        selectedSegmentLabel.numberOfLines = 0
        selectedSegmentLabel.textAlignment = .center
        selectedSegmentView.addSubview(selectedSegmentLabel)
        _ = selectedSegmentView.constrainView(toAllEdges: selectedSegmentLabel)
        refreshSegmentLabels()
    }

    private func refreshBackgroundSegmentInsets() {
        if let oldConstraints = backgroundSegmentInsetConstraints {
            removeConstraints(oldConstraints)
        }
        let insets = UIEdgeInsets(top: backgroundSegmentInset, left: 0, bottom: backgroundSegmentInset, right: 0)
        if let constraints = constrainView(backgroundSegmentView, to: insets) {
             backgroundSegmentInsetConstraints = Array(constraints.values)
        }
    }

    private func refreshSegmentLabels() {
        segmentLabels.forEach { $0.removeFromSuperview() }
        segmentLabelXConstraints.removeAll()

        selectedSegmentLabel.textColor = selectedSegmentLabelTextColor ?? segmentLabelTextColor
        selectedSegmentLabel.font = selectedSegmentLabelFont ?? segmentLabelFont

        segmentLabels = items.map {
            let label = UILabel()
            label.text = $0
            label.backgroundColor = UIColor.clear
            label.textColor = segmentLabelTextColor
            label.font = segmentLabelFont
            label.numberOfLines = 0
            label.textAlignment = .center
            insertSubview(label, belowSubview: selectedSegmentView)
            _ = constrainView(toMiddleVertically: label)
            let constraint = NSLayoutConstraint(
                item: self,
                attribute: .leading,
                relatedBy: .equal,
                toItem: label,
                attribute: .centerX,
                multiplier: 1.0,
                constant: 0
            )
            addConstraint(constraint)
            segmentLabelXConstraints.append(constraint)
            return label
        }

        // If attributed strings exist, use them instead
        guard let attributedItems = attributedItems else { return }
        for (index, attributedItem) in attributedItems.enumerated() {
            segmentLabels[index].attributedText = attributedItem
        }
    }

    // MARK: - Selection

    public func selectItem(at index: Int, animated: Bool = false) {
        guard index != selectedSegmentIndex && index >= 0 && index < items.count else { return }

        selectedSegmentIndex = index
        refreshSelectedSegmentXConstraint(animated: animated)

        let setText = {
            if let attributedItem = self.attributedItems?[index] {
                self.selectedSegmentLabel.attributedText = attributedItem
            } else {
                self.selectedSegmentLabel.text = self.items[index]
            }
        }

        if animated {
            UIView.animate(
                withDuration: 0.2,
                animations: {
                    self.selectedSegmentLabel.alpha = 0
                }, completion: { _ in
                    setText()

                    UIView.animate(withDuration: 0.2) {
                        self.selectedSegmentLabel.alpha = 1
                    }
                }
            )
        } else {
            setText()
        }
    }

    private func refreshSelectedSegmentXConstraint(animated: Bool) {
        let longerDimension = max(frame.width, frame.height)
        let maxConstraintMagnitude = longerDimension / 2

        let segmentWidth = selectedSegmentWidthConstraint.constant
        let segmentCenterOffset = segmentWidth / 2

        // Segment order can be inverted to handle vertical layout
        // (i.e. the case where the first item in a vertical layout would be the last item when transformed horizontally)
        let rawConstrant = CGFloat(selectedSegmentIndex) * segmentWidth + segmentCenterOffset - maxConstraintMagnitude
        selectedSegmentCenterXConstraint.constant = rawConstrant * CGFloat(segmentLayoutInverted ? -1 : 1)

        if animated {
            UIView.animate(withDuration: 0.3, animations: layoutIfNeeded)
        } else {
            layoutIfNeeded()
        }
    }

    // MARK: - Touch Handling

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        let itemCount = items.count
        let longerDimension = max(frame.width, frame.height)
        var xLocation = touch.location(in: self).x
        if segmentLayoutInverted {
            xLocation = longerDimension - xLocation
        }

        let segment = Int(floor(xLocation / (longerDimension / CGFloat(itemCount))))
        if segment != selectedSegmentIndex {
            let canSelectSegment = delegate?.segmentedSlider(self, canSelectSegment: segment) ?? true
            guard canSelectSegment else { return }

            selectItem(at: segment, animated: true)
            sendActions(for: .valueChanged)
        }
    }

    // MARK: - Hit Box Override

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let widthInset: CGFloat = max(0, Constants.minimumTouchableDimension - bounds.width) / 2
        let heightInset: CGFloat = max(0, Constants.minimumTouchableDimension - bounds.height) / 2
        let rect = bounds.insetBy(dx: -widthInset, dy: -heightInset)
        return rect.contains(point)
    }
}
