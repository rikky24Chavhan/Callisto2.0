//
//  OnboardingManagerTests.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/30/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
@testable import MealTrackingPilot

class OnboardingManagerTests: XCTestCase {

    var primaryUserStorage = PilotPrimaryUserStorage(underlyingUserProvider: MockUserStorage())
    fileprivate var mockDefaults = MockUserDefaults()

    lazy var sut: PilotOnboardingManager = PilotOnboardingManager(
        primaryUserStorage: self.primaryUserStorage,
        userDefaults: self.mockDefaults
    )

    func testOnboardingWithNonPrimaryUser() {
        let user = PilotUser(identifier: "mock-user-id", userName: "Participant99", installedDate: Date())
        XCTAssertFalse(primaryUserStorage.isPrimary(user), "User should not be primary")
        XCTAssertFalse(sut.shouldOnboardUser(user), "Should not need to onboard user")
    }

    func testOnboardingWithPrimaryUser() {
        let user = PilotUser(identifier: "mock-user-id", userName: "Participant99", installedDate: Date())
        primaryUserStorage.didLoginWithUser(user)
        XCTAssert(primaryUserStorage.isPrimary(user), "User should be primary")

        XCTAssertTrue(sut.shouldOnboardUser(user), "Should need to onboard user")
        sut.didFinishOnboardingForUser(user)

        XCTAssertFalse(sut.shouldOnboardUser(user), "Should not need to onboard user")
    }

    func testDemoWithNonPrimaryUser() {
        let user = PilotUser(identifier: "mock-user-id", userName: "Participant99", installedDate: Date())
        XCTAssertFalse(primaryUserStorage.isPrimary(user), "User should not be primary")
        XCTAssertFalse(sut.shouldDemoPilot(user), "Should not need to demo user")
    }

    func testDemoWithPrimaryUser() {
        let user = PilotUser(identifier: "mock-user-id", userName: "Participant99", installedDate: Date())
        primaryUserStorage.didLoginWithUser(user)
        XCTAssert(primaryUserStorage.isPrimary(user), "User should be primary")

        XCTAssertTrue(sut.shouldDemoPilot(user), "Should need to demo user")
        sut.didFinishPilotDemo(user)

        XCTAssertFalse(sut.shouldDemoPilot(user), "Should not need to demo user")
    }
}

fileprivate class MockUserDefaults: UserDefaultsProtocol {
    private var bools = [String: Bool]()

    func bool(forKey defaultName: String) -> Bool {
        return bools[defaultName] ?? false
    }

    func set(_ value: Bool, forKey defaultName: String) {
        bools[defaultName] = value
    }
}
