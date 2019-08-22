//
//  MealEventDetailsPortionCell.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 5/3/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

protocol MealEventDetailsPortionCellDelegate: class {
    func portionCell(_ cell: MealEventDetailsPortionCell, didSelectPortion portion: MealEventPortion)
}

class MealEventDetailsPortionCell: UITableViewCell {

    static let preferredHeight: CGFloat = 154.0

    weak var delegate: MealEventDetailsPortionCellDelegate?

    private let portionValues: [MealEventPortion] = MealEventPortion.orderedValues

    @IBOutlet weak var segmentedSlider: SegmentedSlider!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupSegmentedSlider()

        segmentedSlider.selectedSegmentView.addObserver(self, forKeyPath: "bounds", options: .new, context: nil)
    }

    deinit {
        segmentedSlider.selectedSegmentView.removeObserver(self, forKeyPath: "bounds")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let selectedSegmentGradientLayer = segmentedSlider.selectedSegmentView.layer.sublayers?.first else { return }
        selectedSegmentGradientLayer.frame = segmentedSlider.selectedSegmentView.bounds
    }

    private func setupSegmentedSlider() {
        segmentedSlider.attributedItems = portionValues.map {
            let string = $0.displayValue
            let attributedString = NSMutableAttributedString(string: string)
            let nsString = string as NSString
            let newlineLocation = nsString.range(of: "\n").location

            if newlineLocation != NSNotFound && nsString.length > newlineLocation {
                let secondLineStartIndex = newlineLocation + 1
                let secondLineRange = NSMakeRange(secondLineStartIndex, nsString.length - secondLineStartIndex)
                let secondLineAttributes = [NSAttributedStringKey.font : UIFont.openSansFont(size: 14.0)]
                attributedString.setAttributes(secondLineAttributes, range: secondLineRange)
            }

            return attributedString
        }

        segmentedSlider.segmentLabelFont = UIFont.openSansBoldFont(size: 18.0)
        segmentedSlider.segmentLabelTextColor = UIColor.piGreyblue
        segmentedSlider.selectedSegmentLabelTextColor = UIColor.white
        segmentedSlider.backgroundSegmentInset = 8.0
        segmentedSlider.addTarget(self, action: #selector(segmentValueChanged), for: .valueChanged)

        // Configure shadow
        segmentedSlider.layer.shadowOpacity = 0.1
        segmentedSlider.layer.shadowOffset = CGSize(width: 0, height: 2)
        segmentedSlider.layer.shadowRadius = 4.0

        // Configure background segment
        let backgroundSegmentView = segmentedSlider.backgroundSegmentView
        backgroundSegmentView.backgroundColor = UIColor.white
        backgroundSegmentView.layer.masksToBounds = true
        backgroundSegmentView.layer.cornerRadius = 18.0
        backgroundSegmentView.layer.borderWidth = 1.0
        backgroundSegmentView.layer.borderColor = UIColor.piLightBlueGreyTwo.cgColor

        // Configure selected segment
        let selectedSegmentView = segmentedSlider.selectedSegmentView
        selectedSegmentView.layer.masksToBounds = true
        selectedSegmentView.layer.cornerRadius = 20.0
        let selectedSegmentGradientLayer = CAGradientLayer()
        selectedSegmentGradientLayer.frame = selectedSegmentView.bounds
        selectedSegmentGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        selectedSegmentGradientLayer.endPoint = CGPoint(x: 1, y: 0)
        selectedSegmentGradientLayer.colors = [UIColor.piCommonMealGradientStartColor.cgColor, UIColor.piCommonMealGradientFinishColor.cgColor]
        selectedSegmentView.layer.insertSublayer(selectedSegmentGradientLayer, at: 0)
    }

    @objc private func segmentValueChanged(_ sender: SegmentedSlider) {
        delegate?.portionCell(self, didSelectPortion: portionValues[sender.selectedSegmentIndex])
    }

    func configure(with portion: MealEventPortion) {
        guard let index = portionValues.index(of: portion) else { return }
        segmentedSlider.selectItem(at: index)
    }

    // MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "bounds" {
            guard
                let newBounds = change?[.newKey] as? CGRect,
                let selectedSegmentGradientLayer = segmentedSlider.selectedSegmentView.layer.sublayers?.first else { return }
            selectedSegmentGradientLayer.frame = newBounds
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

extension MealEventPortion {
    fileprivate var displayValue: String {
        switch self {
        case .usual:
            return "\(rawValue)\namount".uppercased()
        default:
            return rawValue.uppercased()
        }
    }
}
