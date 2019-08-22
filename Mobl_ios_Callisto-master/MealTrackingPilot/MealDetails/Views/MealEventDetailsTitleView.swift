//
//  MealEventDetailsTitleView.swift
//  MealTrackingPilot
//
//  Created by Colden Prime on 5/23/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

class MealEventDetailsTitleView: UIView {

    private struct Constants {
        static var maximumTitleWidth: CGFloat {
            switch UIDevice.current.screenType {
            case .small:
                return 211
            case .notch:
                return 276
            default:
                return 311
            }
        }
    }

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var arrowView: UIImageView!
    @IBOutlet weak var leadingFlushConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingSuperviewConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingArrowConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel.textColor = UIColor.piDenim
        subtitleLabel.textColor = UIColor.piBlueyGrey
        subtitleLabel.font = UIFont.openSansSemiboldFont(size: 12.0)

        updateSize()
    }

    func configure(viewModel: MealEventDetailsViewModel) {
        if viewModel.canSwapMeal {
            leadingFlushConstraint.priority = 1.layoutPriority
            leadingPaddingConstraint.priority = 999.layoutPriority
            trailingSuperviewConstraint.priority = 1.layoutPriority
            trailingArrowConstraint.priority = 999.layoutPriority
        } else {
            leadingFlushConstraint.priority = 999.layoutPriority
            leadingPaddingConstraint.priority = 1.layoutPriority
            trailingSuperviewConstraint.priority = 999.layoutPriority
            trailingArrowConstraint.priority = 1.layoutPriority
        }
        arrowView.isHidden = !viewModel.canSwapMeal
        backgroundView.isHidden = !viewModel.canSwapMeal

        let titleFontSize: Float = viewModel.mealLocationAndPortion == nil ? 17 : 16
        titleLabel.font = UIFont.openSansSemiboldFont(size: titleFontSize)
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.mealLocationAndPortion

        updateSize()
    }

    func updateSize() {
        translatesAutoresizingMaskIntoConstraints = false
        setNeedsLayout()
        let editableMealTitleSize = CGSize(width: Constants.maximumTitleWidth, height: 36)
        sizeThatFits(editableMealTitleSize)
        layoutIfNeeded()

        if frameSize.width > Constants.maximumTitleWidth {
            self.frame.size.width = Constants.maximumTitleWidth
        }

        translatesAutoresizingMaskIntoConstraints = true
    }
}
