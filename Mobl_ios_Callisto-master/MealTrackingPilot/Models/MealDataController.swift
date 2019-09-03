//
//  MealDataController.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/15/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import RxSwift
import Intrepid

enum SaveResult<Value> {
    case synchronized(Value)
    case remoteOnly(Value, Error)
    case localOnly(Value, Error)
    case failure(Error)
}

protocol MealDataController {
    var loggedMealEvents: Observable<[MealEvent]> { get }
    func getLoggedMealEvents(completion: voidRequestCompletion?)
    func saveMealEvent(_ mealEvent: MealEvent, completion: ((SaveResult<MealEvent>) -> Void)?)
    func reportMealEvent(_ mealEvent: MealEvent, completion: mealEventCompletion?)
    func observableMeals(forClassification classification: MealClassification) -> Observable<[Meal]>
    func getMeals(forClassification classification: MealClassification, completion: voidRequestCompletion?)
    func saveMeal(_ meal: Meal, shouldValidate: Bool, completion: ((SaveResult<Meal>) -> Void)?)
    var mealStatistics: Observable<MealStatistics> { get }
    func reset()
}
