//
//  MealOccasionPickerItemView.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/21/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

final class MealOccasionPickerItemView: UIView {
    @IBOutlet weak var iconContainerView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    func configureWithViewModel(_ viewModel: MealOccasionPickerItemViewModel) {
        alpha = viewModel.alpha
        iconContainerView.transform = viewModel.itemTransform
        iconImageView.image = viewModel.icon
        titleLabel.text = viewModel.title
        titleLabel.font = viewModel.titleFont
    }

    class var preferredWidth: CGFloat {
        return 90
    }
}
