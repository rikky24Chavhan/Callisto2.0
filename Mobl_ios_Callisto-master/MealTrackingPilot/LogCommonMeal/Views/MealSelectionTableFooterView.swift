//
//  MealSelectionTableFooterView.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/20/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

protocol MealSelectionTableFooterViewDelegate: class {
    func mealSelectionTableFooterDidSelectAddNewMeal(_ footerView: MealSelectionTableFooterView)
}

public final class MealSelectionTableFooterView: UIView {
    @IBAction func addNewMealButtonPressed(_ sender: UIButton) {
        delegate?.mealSelectionTableFooterDidSelectAddNewMeal(self)
    }

    var delegate: MealSelectionTableFooterViewDelegate?

    public override func layoutSubviews() {
        super.layoutSubviews()

        // HACK: workaround for iOS 9.2 tableFooterView height handling
        let height = systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        if height != frame.height {
            var frame = self.frame
            frame.size.height = height
            self.frame = frame
        }
    }
}
