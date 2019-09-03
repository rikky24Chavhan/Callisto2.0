//
//  MockPilotAPIClient.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/27/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import Realm
import Intrepid
@testable import MealTrackingPilot

enum MockPilotAPIClientError: Error {
    case errorFromServer
}

class MockPilotAPIClient: PilotAPIClient {
    var mockCreateMealEventResponse: Result<RealmMealEvent> = .success(RealmMealEvent())
    var mockCreateImageURLResponse: Result<String> = .success("")
    var mockCreateLocationResponse: Result<Void> = .success(())

    override func createMeal(_ meal: Meal, completion: ((Result<RealmMeal>) -> Void)?) {
        completion?(.success(RealmMeal()))
    }

    override func createMealEvent(_ mealEvent: MealEvent, completion: ((Result<RealmMealEvent>) -> Void)?) {
        completion?(mockCreateMealEventResponse)
    }

    override func createLocation(_ location: Location, completion: ((Result<Void>) -> Void)?) {
        completion?(mockCreateLocationResponse)
    }
}
