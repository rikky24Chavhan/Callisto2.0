//
//  MockMealDataController.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 5/3/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import RxSwift
@testable import MealTrackingPilot

final class MockMealDataController: MealDataController {
   
    enum MockMealDataControllerError: Error {
        case defaultMockSaveMealFailure
    }

    private var mockMealsVariable: Variable<[Meal]>
    var mockMeals: [Meal] {
        return mockMealsVariable.value
    }

    private var mockMealEventsVariable: Variable<[MealEvent]>
    var mockMealEvents: [MealEvent] {
        return mockMealEventsVariable.value
    }

    let apiClient = MockPilotAPIClient()

    init(mockMeals: [Meal] = [], mockMealEvents: [MealEvent] = []) {
        self.mockMealsVariable = Variable(mockMeals)
        self.mockMealEventsVariable = Variable(mockMealEvents)
    }

    func observableMeals(forClassification classification: MealClassification) -> Observable<[Meal]> {
        return mockMealsVariable.asObservable()
    }

    func getMeals(forClassification classification: MealClassification, completion: voidRequestCompletion?) {
        completion?(.success(()))
    }

    func saveMeal(_ meal: Meal, shouldValidate: Bool = false, completion: ((SaveResult<Meal>) -> Void)?) {
        mockMealsVariable.value.append(meal)
        completion?(.synchronized(meal))
    }

    func saveMealEventImage(_ image: UIImage, fileName: String, completion: ((SaveResult<URL>) -> Void)?) {
        completion?(.synchronized(URL(string: fileName)!))
    }

    var loggedMealEvents: Observable<[MealEvent]> {
        return mockMealEventsVariable.asObservable()
    }

    func getLoggedMealEvents(completion: voidRequestCompletion?) {
        completion?(.success(()))
    }

    func saveMealEvent(_ mealEvent: MealEvent, completion: ((SaveResult<MealEvent>) -> Void)?) {
        let meal = mealEvent.meal
        if meal.isLocalOnly {
            mockMealsVariable.value.append(meal)
        }
        
        mockMealEventsVariable.value.append(mealEvent)
        completion?(.synchronized(mealEvent))
    }

    func reportMealEvent(_ mealEvent: MealEvent, completion: mealEventCompletion?) {
        mealEvent.isFlagged = true
        completion?(.success(mealEvent))
    }

    var mealStatistics: Observable<MealStatistics> {
        return Observable.just(MealStatistics(mealEvents: []))
    }

    func reset() {
        mockMealsVariable.value.removeAll()
        mockMealEventsVariable.value.removeAll()
    }
}
