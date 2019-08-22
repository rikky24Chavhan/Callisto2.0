//
//  MealStatistics.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/29/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

public final class MealStatistics {

    // MARK: - Properties

    // meal id : count
    private var totalMealTallyDictionary = [String : Int]()

    // MARK: - Lifecycle

    init(mealEvents: [MealEvent]) {
        buildStatistics(from: mealEvents)
    }

    // MARK: - Actions

    func totalCountForMeal(_ meal: Meal) -> Int {
        return totalMealTallyDictionary[meal.localIdentifier] as Int? ?? 0
    }

    private func buildStatistics(from mealEvents: [MealEvent]) {
        mealEvents.forEach { mealEvent in
            let mealID = mealEvent.meal.localIdentifier
            totalMealTallyDictionary[mealID] = (totalMealTallyDictionary[mealID] ?? 0) + 1
        }
    }
}
