//
//  MockPilotAPIClient.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/27/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import Realm
@testable import MealTrackingPilot

enum MockPilotAPIClientError: Error {
    case errorFromServer
}

class MockPilotAPIClient: PilotAPIClient {
    var mockCreateMealEventResponse: Result<RealmMealEvent,Error> = .success(RealmMealEvent())
    var mockCreateImageURLResponse: Result<String,Error> = .success("")
    var mockCreateLocationResponse: Result<Void?,Error> = .success(())

    override func createMeal(_ meal: Meal, completion: relamMealCompletion?) {
        completion?(.success(RealmMeal()))
    }

    override func createMealEvent(_ mealEvent: MealEvent, completion: relamMealEventCompletion?) {
        completion?(mockCreateMealEventResponse)
    }

    override func createLocation(_ location: Location, completion: voidRequestCompletion?) {
        completion?(mockCreateLocationResponse)
    }
}
