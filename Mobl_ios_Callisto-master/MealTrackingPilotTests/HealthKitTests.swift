//
//  HealthKitTests.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 4/24/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import HealthKit
import RealmSwift
@testable import MealTrackingPilot

class HealthKitTests: XCTestCase {

    let realmConfiguration = Realm.Configuration(inMemoryIdentifier: "HealthKitTests-\(UUID())")
    lazy var realm: Realm = {
        return try! Realm(configuration: self.realmConfiguration)
    }()

    let mockAPIClient = MockPilotAPIClient()
    let mockLoginUserProvider = MockLoginUserProvider(mockIsLoggedInAsPrimaryUser: true)
    let userDefaults = UserDefaults(suiteName: "HealthKitTests")!
    var mockHealthStore = MockHealthStore()

    override func setUp() {
        super.setUp()

        try! realm.write {
            realm.deleteAll()
        }

        mockHealthStore = MockHealthStore()
    }

    // MARK: - Init Tests

    private func getTestQuantitySample(steps: Int) -> HKQuantitySample {
        let quantityType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: Double(steps))
        let startDate = Date(timeIntervalSince1970: 1493053400)
        let endDate = Date(timeIntervalSince1970: 1493053440)
        return HKQuantitySample(type: quantityType, quantity: quantity, start: startDate, end: endDate)
    }

    func testStepSampleInitWithHKQuantitySample() {
        let steps = 100
        let quantitySample = getTestQuantitySample(steps: steps)

        let stepSample = RealmStepSample(sample: quantitySample)
        XCTAssertEqual(stepSample.startDate, quantitySample.startDate)
        XCTAssertEqual(stepSample.endDate, quantitySample.endDate)
        XCTAssertEqual(stepSample.steps, steps)
        XCTAssertNotNil(NSUUID(uuidString: stepSample.localIdentifier), "Local Identifier should be UUID string")
    }

    private func getTestStatistics(steps: Int) -> MockHKStatistics {
        let startDate = Date(timeIntervalSince1970: 1493053400)
        let endDate = Date(timeIntervalSince1970: 1493053440)
        return MockHKStatistics(steps: Double(steps), startDate: startDate, endDate: endDate)
    }

    func testStepSampleInitWithHKStatistics() {
        let steps = 100
        let statistics = getTestStatistics(steps: steps)

        // Test valid HKStatistics
        statistics.hasSumQuantity = true
        guard let stepSample = RealmStepSample(sumStatistics: statistics) else {
            XCTFail("Unable to create RealmStepSample with valid HKStatistics object")
            return
        }

        XCTAssertEqual(stepSample.startDate, statistics.startDate)
        XCTAssertEqual(stepSample.endDate, statistics.endDate)
        XCTAssertEqual(stepSample.steps, steps)
        XCTAssertNotNil(NSUUID(uuidString: stepSample.localIdentifier), "Local Identifier should be UUID string")

        // Test invalid HKStatistics
        statistics.hasSumQuantity = false
        let nilStepSample = RealmStepSample(sumStatistics: statistics)
        XCTAssertNil(nilStepSample)
    }

    func testStepSampleJSON() {
        let stepSample = RealmStepSample()
        stepSample.startDate = Date(timeIntervalSince1970: 1493053400)
        stepSample.endDate = Date(timeIntervalSince1970: 1493053440)
        stepSample.steps = 100

        let jsonEncoder = JSONEncoder.CallistoJSONEncoder()
        guard
            let data = try? jsonEncoder.encode(stepSample),
            let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any],
            let startDateString = json["started_at"] as? String,
            let endDateString = json["ended_at"] as? String,
            let steps = json["steps"] as? Int
            else {
                XCTFail("Failed to map to JSON")
                return
        }
        XCTAssertEqual(startDateString, DateFormatter.pilotStringFromDate(stepSample.startDate))
        XCTAssertEqual(endDateString, DateFormatter.pilotStringFromDate(stepSample.endDate))
        XCTAssertEqual(steps, stepSample.steps)
    }

    func testHealthKitControllerRequestAuthorizationSuccess() {
        let healthKitController = HealthKitController(
            healthStore: mockHealthStore,
            realm: realm,
            apiClient: mockAPIClient,
            loginUserProvider: mockLoginUserProvider,
            userDefaults: userDefaults,
            healthDataAvailableGetter: { true })

        let asyncExpectation = expectation(description: "Authorization successful")
        healthKitController.requestAuthorization { result in
            switch result{
            case .success( _):
                asyncExpectation.fulfill()
            case .failure(_):
                break
            }
        }
        waitForExpectations(timeout: 0.1) { error in
            XCTAssertNil(error)

            guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
                XCTFail("Unable to create HKSampleType for stepCount")
                return
            }
            XCTAssert(self.mockHealthStore.readTypesRequested.contains(stepType))
        }
    }

    func testHealthKitControllerRequestAuthorizationErrorFailure() {
        let healthKitController = HealthKitController(
            healthStore: mockHealthStore,
            realm: realm,
            apiClient: mockAPIClient,
            loginUserProvider: mockLoginUserProvider,
            userDefaults: userDefaults,
            healthDataAvailableGetter: { true })

        mockHealthStore.requestAuthorizationShouldSucceed = false

        let asyncExpectation = expectation(description: "Authorization failed")
        healthKitController.requestAuthorization { result in
            switch result{
            case .success( _):
                break
            case .failure(_):
                asyncExpectation.fulfill()
            }
        }

        wait(for: [asyncExpectation], timeout: 0.1)
    }

    func testHealthKitControllerRequestAuthorizationHealthKitUnavailableFailure() {
        let healthKitController = HealthKitController(
            healthStore: mockHealthStore,
            realm: realm,
            apiClient: mockAPIClient,
            loginUserProvider: mockLoginUserProvider,
            userDefaults: userDefaults,
            healthDataAvailableGetter: { false })

        let asyncExpectation = expectation(description: "HealthKit unavailable error")
        healthKitController.requestAuthorization { result in
            switch result{
            case .success( _):
                break
            case .failure(let error):
                if error == HealthKitController.HealthKitError.healthKitUnavailable{
                    asyncExpectation.fulfill()
                }
                break
            }
            
        }

        waitForExpectations(timeout: 0.1) { error in
            XCTAssertNil(error)
            XCTAssert(self.mockHealthStore.readTypesRequested.isEmpty)
        }
    }

    func testQueryNewHourlyStepSamples() {
        let healthKitController = HealthKitController(
            healthStore: mockHealthStore,
            realm: realm,
            apiClient: mockAPIClient,
            loginUserProvider: mockLoginUserProvider,
            userDefaults: userDefaults,
            healthDataAvailableGetter: { true })

        healthKitController.queryNewHourlyStepSamples()

        guard let statisticsCollectionQuery = mockHealthStore.lastQuery as? HKStatisticsCollectionQuery else {
            XCTFail("Expected call to create a HKStatisticsCollectionQuery but it didn't")
            return
        }

        // Test that anchor date is the start of the hour
        let anchorDate = statisticsCollectionQuery.anchorDate
        XCTAssertEqual(anchorDate.minute, 0)
        XCTAssertEqual(anchorDate.second, 0)

        // Query properties should be set correctly
        XCTAssertEqual(statisticsCollectionQuery.objectType?.identifier, HKQuantityTypeIdentifier.stepCount.rawValue)
        XCTAssertEqual(statisticsCollectionQuery.intervalComponents.hour, 1)
        XCTAssert(statisticsCollectionQuery.options.contains(.cumulativeSum))
    }

    func testQueryCumulativeSumHealthKitUnavailable() {
        let healthKitController = HealthKitController(
            healthStore: mockHealthStore,
            realm: realm,
            apiClient: mockAPIClient,
            loginUserProvider: mockLoginUserProvider,
            userDefaults: userDefaults,
            healthDataAvailableGetter: { false })

        let asyncExpectation = expectation(description: "HealthKit unavailable error")

        healthKitController.queryCumulativeSum(.steps, startDate: Date(), intervalComponents: DateComponents()) { result in
            switch result {
            case .success( _):
                break
            case .failure(let error):
                if error == HealthKitController.HealthKitError.healthKitUnavailable{
                    asyncExpectation.fulfill()
                }
                break
            }
        }
        wait(for: [asyncExpectation], timeout: 0.1)
    }
}
