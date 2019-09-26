//
//  RealmMealDataControllerTests.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/3/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import RealmSwift
import RxSwift
@testable import MealTrackingPilot

class RealmMealDataControllerTests: XCTestCase {

    let realmConfiguration = Realm.Configuration(inMemoryIdentifier: "RealmMealDataControllerTests-\(UUID())")

    let mockAPIClient = MockPilotAPIClient()
    let mockURLSession = MockURLSession()
    let mockFileManager = MockFileManager()

    lazy var realm: Realm = {
        return try! Realm(configuration: self.realmConfiguration)
    }()

    let mockMealEventLocalIdentifier = "test-meal-event-local-identifier-waffle"

    private let bag = DisposeBag()

    override func setUp() {
        super.setUp()

        RealmSeeder.seedRealm(realm: realm)
    }

    private func createMockTestMealEvent() -> RealmMealEvent {
        let testMeal: RealmMeal = realm.object(ofType: RealmMeal.self, forPrimaryKey: "local-Bacon-and-Waffles")!

        let mockMealEvent = RealmMealEvent()
        mockMealEvent.localIdentifier = mockMealEventLocalIdentifier
        mockMealEvent.isDirty = true
        mockMealEvent.meal = testMeal

        return mockMealEvent
    }

    func testCreateMealEventSuccess() {
        let sut: RealmMealDataController

        do {
            sut = try RealmMealDataController(realmConfiguration: realmConfiguration, apiClient: mockAPIClient)
        } catch(_) {
            XCTFail("Should create RealmMealDataController.")
            return
        }

        let asyncExpectation = expectation(description: "Async meal creation operation")

        let mockMealEvent = createMockTestMealEvent()
        mockAPIClient.mockCreateMealEventResponse = .success(mockMealEvent)

        var saveMealEventResult: SaveResult<MealEvent>? = nil
        sut.saveMealEvent(mockMealEvent, completion: { result in
            saveMealEventResult = result
            asyncExpectation.fulfill()
        })

        waitForExpectations(timeout: 1) { [weak self] error in
            XCTAssertNil(error)

            guard let welf = self else { return }

            guard let result = saveMealEventResult else {
                XCTFail("Should receive callback with result.")
                return
            }

            switch result {
            case .synchronized(let resultMealEvent):
                XCTAssertEqual(mockMealEvent.localIdentifier, resultMealEvent.localIdentifier, "Should propagate response with created meal event.")

                let mealEventFromRealm = welf.realm.object(ofType: RealmMealEvent.self, forPrimaryKey: welf.mockMealEventLocalIdentifier)
                XCTAssertNotNil(mealEventFromRealm, "Should be able to retreive new meal event from realm")
                XCTAssertFalse(mealEventFromRealm!.isDirty, "Meal event should not be marked dirty.")
            default:
                XCTFail("Should receive synchronized response")
            }
        }
    }

    func testCreateMealLocalOnly() {
        let sut: RealmMealDataController

        do {
            sut = try RealmMealDataController(realmConfiguration: realmConfiguration, apiClient: mockAPIClient)
        } catch(_) {
            XCTFail("Should create RealmMealDataController.")
            return
        }

        let asyncExpectation = expectation(description: "Async meal event creation operation")

        let mockMealEvent = createMockTestMealEvent()
        // TODO: Replace this dummy error with a more realistic error type from the actual APIClient library
        mockAPIClient.mockCreateMealEventResponse = .failure(MockPilotAPIClientError.errorFromServer)

        var saveMealEventResult: SaveResult<MealEvent>? = nil
        sut.saveMealEvent(mockMealEvent, completion: { result in
            saveMealEventResult = result
            asyncExpectation.fulfill()
        })

        waitForExpectations(timeout: 1) { [weak self] error in
            XCTAssertNil(error)

            guard let welf = self else { return }

            guard let result = saveMealEventResult else {
                XCTFail("Should receive callback with result.")
                return
            }

            switch result {
            case .localOnly(let resultMealEvent, let error):
                XCTAssertEqual(mockMealEvent.localIdentifier, resultMealEvent.localIdentifier, "Should propagate response with created meal event.")
                XCTAssert(error == MockPilotAPIClientError.errorFromServer, "Should propagate error from server.")

                let mealEventFromRealm = welf.realm.object(ofType: RealmMealEvent.self, forPrimaryKey: welf.mockMealEventLocalIdentifier)
                XCTAssertNotNil(mealEventFromRealm, "Should be able to retreive new meal event from realm")
                XCTAssertTrue(mealEventFromRealm!.isDirty, "Meal event should be marked dirty.")
            default:
                XCTFail("Should receive synchronized response")
            }
        }
    }

    func testObservableMealsAreNotHidden() {
        let sut: RealmMealDataController

        do {
            sut = try RealmMealDataController(realmConfiguration: realmConfiguration, apiClient: mockAPIClient)
        } catch(_) {
            XCTFail("Should create RealmMealDataController.")
            return
        }

        let commonMealsUpdatedExpectation = expectation(description: "Common meals updated")

        // Get the initial state of the common meals observable
        let commonMealsObservable = sut.observableMeals(forClassification: .common)
        var currentCommonMeals: [Meal] = []
        commonMealsObservable.subscribe(onNext: {
            if !currentCommonMeals.isEmpty {
                defer { commonMealsUpdatedExpectation.fulfill() }
            }
            currentCommonMeals = $0
        }) >>> bag

        let initialCount = currentCommonMeals.count

        // Hide one of our meals
        guard let meal = currentCommonMeals.first as? RealmMeal else {
            XCTFail("Unable to get RealmMeal object to set isHidden")
            return
        }

        try! realm.write {
            meal.isHidden = true
        }

        // Expect that the hidden meal is no longer returned in the observable
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertEqual(currentCommonMeals.count, initialCount - 1)
        }
    }
}
