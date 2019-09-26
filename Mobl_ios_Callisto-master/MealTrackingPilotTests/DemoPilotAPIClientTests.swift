//
//  DemoPilotAPIClientTests.swift
//  MealTrackingPilot
//
//  Created by Colden Prime on 5/19/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
@testable import MealTrackingPilot

class DemoPilotAPIClientTests: XCTestCase {
    let sut = DemoPilotAPIClient()

    func testCreateMealSuccess() {
        let meal = RealmMeal()
        var mealResult: Result<RealmMeal,Error>?

        let asyncExpectation = expectation(description: "Meal Creation")
        sut.createMeal(meal) { result in
            mealResult = result
            asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0) { error in
            if let mealResult = mealResult {
                switch mealResult {
                case .success(let value):
                    XCTAssertTrue(true, "Should return a successful result")
                    XCTAssertNotNil(value.identifier, "Should set the identifier of the resulting meal")
                case .failure(_):
                    XCTAssertFalse(false, "Should return a failure result")
                }
            } else {
                XCTFail("Failed to generate a request result")
            }
        }
    }

    func testGetMealEvents() {
        var mealEventsResult: Result<[RealmMealEvent],Error>?

        let asyncExpectation = expectation(description: "Meal Event Retrieval")
        sut.getMealEvents { result in
            mealEventsResult = result
            asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0) { error in
            if let mealEventsResult = mealEventsResult {
                switch mealEventsResult {
                case .success(let resultEvents):
                    XCTAssertEqual(resultEvents, [], "Should return an empty result")
                case .failure(_):
                    XCTAssertFalse(false, "Should return a failure result")
                }
            } else {
                XCTFail("Failed to generate a request result")
            }
        }
    }

    func testCreateMealEventSuccess() {
        let realmMealEvent = RealmMealEvent()
        var mealEventResult: Result<RealmMealEvent,Error>?

        let asyncExpectation = expectation(description: "Meal Event Creation")
        sut.createMealEvent(realmMealEvent) { result in
            mealEventResult = result
            asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0) { error in
            if let mealEventResult = mealEventResult {
                switch mealEventResult {
                case .success(let value):
                    XCTAssertTrue(true, "Should return a successful result")
                    XCTAssertNotNil(value.identifier, "Should set the identifier of the resulting meal event")
                case .failure(_):
                    XCTAssertFalse(false, "Should return a failure result")
                }
            } else {
                XCTFail("Failed to generate a request result")
            }
        }
    }

    func testUpdateMealEventSuccess() {
        let realmMealEvent = RealmMealEvent()
        realmMealEvent.identifier = "id"
        var mealEventResult: Result<RealmMealEvent,Error>?

        let asyncExpectation = expectation(description: "Meal Event Creation")
        sut.updateMealEvent(realmMealEvent) { result in
            mealEventResult = result
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0) { error in
            if let mealEventResult = mealEventResult {
                switch mealEventResult{
                case .success(_):
                    XCTAssertTrue(true, "Should return a successful result")
                case .failure(_):
                    XCTAssertFalse(false, "Should return a failure result")
                }
            } else {
                XCTFail("Failed to generate a request result")
            }
        }
    }

    func testReportMealEvents() {
        let realmMealEvent = RealmMealEvent()
        var reportResult: Result<[RealmMealEvent],Error>?

        let asyncExpectation = expectation(description: "Report Meal Event")
        sut.reportMealEvents([realmMealEvent]) { result in
            reportResult = result
            asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0) { error in
            if let reportResult = reportResult {
                switch reportResult {
                case .success( _):
                    XCTAssertTrue(true, "Should return a successful result")
                    XCTAssertTrue(realmMealEvent.isFlagged, "Meal Event should be flagged")
                case .failure(_):
                    XCTAssertFalse(false, "Should return a failure result")
                }
            } else {
                XCTFail("Failed to generate a request result")
            }
        }
    }
}
