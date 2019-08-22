//
//  AppNavigatorTests.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 5/8/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import RealmSwift
@testable import MealTrackingPilot

class AppNavigatorTests: XCTestCase {

    let realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "AppNavigatorTests-\(UUID())"))
    let apiClient = MockPilotAPIClient()
    let loginClient = MockLoginClient()
    let userProvider = MockLoginUserProvider()
    let userDefaults = UserDefaults(suiteName: "AppNavigatorTests")!

    lazy var primaryUserStorage: PrimaryUserStorage = PilotPrimaryUserStorage(underlyingUserProvider: MockUserStorage())
    lazy var onboardingManager: OnboardingManager = PilotOnboardingManager(
        primaryUserStorage: self.primaryUserStorage,
        userDefaults: self.userDefaults
    )

    lazy var mealDataController: MockMealDataController = MockMealDataController()
    lazy var healthKitController: HealthKitController = HealthKitController(
        healthStore: MockHealthStore(),
        realm: self.realm,
        apiClient: self.apiClient,
        loginUserProvider: self.userProvider,
        userDefaults: self.userDefaults,
        healthDataAvailableGetter: { true })

    lazy var locationController: LocationController = LocationController(
        locationManager: MockLocationManager(),
        realm: self.realm,
        apiClient: self.apiClient,
        loginUserProvider: self.userProvider,
        monitorMode: .frequent,
        authorizationStatusGetter: { .authorizedAlways })

    var sut: AppNavigator!

    override func setUp() {
        super.setUp()
        sut = AppNavigator(window: nil, apiClient: apiClient, loginClient: loginClient, userProvider: userProvider, onboardingManager: onboardingManager, mealDataController: mealDataController, healthKitController: healthKitController, locationController: locationController)
    }

    override func tearDown() {
        sut = nil
    }

    func testLogoutResetsDataController() {
        // Add a test meal to the data controller
        mealDataController.saveMeal(RealmMeal(), completion: nil)

        sut.loginClientDidDisconnect(loginClient)
        XCTAssert(mealDataController.mockMeals.isEmpty, "Data controller should be reset after logging out")
    }
}
