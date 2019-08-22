//
//  DashboardTableViewCellViewModel.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/15/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import RealmSwift

public final class DashboardTableViewCellViewModel {

    // MARK: - Properties

    private struct Constants {
        static let commonMealColor = UIColor.piTopaz
        static let testMealColor = UIColor.piLightOrange

        static let testMealCircleProgressInnerCircleColor = UIColor.piLightOrange
        static let testMealCircleProgressOuterRingTrackColor = UIColor(white: 1.0, alpha: 0.4)
        static let testMealCircleProgressOuterRingProgresscolor = UIColor.white

        static let commonMealCircleProgressInnerCircleColor = UIColor.piTopaz
        static let commonMealCircleProgressOuterRingTrackColor = UIColor.piTopaz40
    }

    let mealEvent: MealEvent
    private let mealStatistics: MealStatistics

    private lazy var meal: Meal = self.mealEvent.meal

    var isCommon: Bool {
        return mealEvent.classification == .common
    }

    lazy var tintColor: UIColor = {
        return self.isCommon ? Constants.commonMealColor : Constants.testMealColor
    }()

    lazy var imageURL: URL? = {
        return self.mealEvent.imageURL
    }()

    lazy var imageURLRequest: URLRequest? = {
        return self.mealEvent.imageURLRequest
    }()

    lazy var circleProgressInnerCircleColor: UIColor = {
        return self.isCommon ? Constants.commonMealCircleProgressInnerCircleColor : Constants.testMealCircleProgressInnerCircleColor
    }()

    lazy var circleProgressOuterCircleTrackColor: UIColor = {
        return self.isCommon ? Constants.commonMealCircleProgressOuterRingTrackColor : Constants.testMealCircleProgressOuterRingTrackColor
    }()

    lazy var circleProgressRingColor: UIColor? = {
        return self.isCommon ? nil : Constants.testMealCircleProgressOuterRingProgresscolor
    }()

    // MARK: - Lifecycle

    init(mealEvent: MealEvent, stats: MealStatistics) {
        self.mealEvent = mealEvent
        self.mealStatistics = stats
    }

    // MARK: - Actions

    var numberOfTimesMealLogged: Int {
        return mealStatistics.totalCountForMeal(meal)
    }

    var mealName: String {
        return meal.name
    }

    var mealLocation: String? {
        return meal.location
    }

    var mealLogGoal: Int {
        return meal.loggingGoal
    }

    var portionIndidatorImage: UIImage? {
        return mealEvent.portion.indicatorImage
    }

    var portionDescription: String? {
        return mealEvent.portion.displayValue
    }

    var noteIndicatorHidden: Bool {
        return mealEvent.note.ip_length == 0
    }

    var reportButtonHidden: Bool {
        return mealEvent.isFlagged
    }

    var flagIndicatorHidden: Bool {
        return !mealEvent.isFlagged
    }

    var dosageRecommendationHidden: Bool {
        return !meal.hasDosingRecommendation
    }
    
    var shouldAnimateReportCompletion: Bool = false
}

extension MealEventPortion {
    fileprivate var displayValue: String {
        return rawValue.uppercased()
    }

    fileprivate var indicatorImage: UIImage {
        switch self {
        case .usual:
            return #imageLiteral(resourceName: "mealAmountUsual")
        case .less:
            return #imageLiteral(resourceName: "mealAmountLess")
        case .more:
            return #imageLiteral(resourceName: "mealAmountMore")
        }
    }
}
