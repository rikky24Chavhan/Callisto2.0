//
//  MealSelectionCellViewModel.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/19/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import RxSwift

struct MealSelectionCellViewModel {
    private(set) var mealSelection: MealSelection

    private var meal: Meal {
        return mealSelection.meal
    }

    var mealClassification: MealClassification {
        return meal.classification
    }

    var mealName: String {
        return meal.name
    }

    var hasDosageRecommendation: Bool {
        return meal.hasDosingRecommendation
    }

    private var mealNameFontSize: Float {
        return 16
    }

    var mealNameFont: UIFont {
        return mealSelection.selected ? UIFont.openSansSemiboldFont(size: mealNameFontSize) : UIFont.openSansFont(size: mealNameFontSize)
    }

    var mealLocationAndPortion: String? {
        guard let location = meal.location else { return nil }

        let roundedPortionOuncesString = "\(Int(meal.portionOunces))"
        return location + " • " + roundedPortionOuncesString + "oz"
    }

    var dosageRecommendationText: String? {
        return hasDosageRecommendation ? "Dosage recommendation" : nil
    }

    var numberOfTimesMealLogged: Int {
        return mealSelection.timesLogged
    }

    var mealLogGoal: Int {
        return meal.loggingGoal
    }

    var selectionIconImageName: String {
        return mealSelection.selected ? "radioOn" : "radioOff"
    }

    var doseIconHidden: Bool {
        return !hasDosageRecommendation
    }
}
