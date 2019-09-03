//
//  OnboardingManager.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/27/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

protocol UserDefaultsProtocol {
    func bool(forKey defaultName: String) -> Bool
    func set(_ value: Bool, forKey defaultName: String)
}

extension UserDefaults: UserDefaultsProtocol {}

protocol OnboardingManager {
    func shouldOnboardUser(_ user: User) -> Bool
    func didFinishOnboardingForUser(_ user: User)
    func shouldDemoPilot(_ user: User) -> Bool
    func didFinishPilotDemo(_ user: User)
}

class PilotOnboardingManager: OnboardingManager {
    private let primaryUserStorage: PrimaryUserStorage
    private var userDefaults: UserDefaultsProtocol

    init(primaryUserStorage: PrimaryUserStorage, userDefaults: UserDefaultsProtocol = UserDefaults.standard) {
        self.primaryUserStorage = primaryUserStorage
        self.userDefaults = userDefaults
    }

    func shouldOnboardUser(_ user: User) -> Bool {
        return primaryUserStorage.isPrimary(user) && !hasFinishedOnboarding
    }

    func didFinishOnboardingForUser(_ user: User) {
        if primaryUserStorage.isPrimary(user) {
            hasFinishedOnboarding = true
        }
    }

    private let onboardingDefaultsKey = "io.intrepid.MealTrackerPilot.hasFinishedOnboarding"

    private var hasFinishedOnboarding: Bool {
        get {
            return userDefaults.bool(forKey: onboardingDefaultsKey)
        }
        set {
            userDefaults.set(newValue, forKey: onboardingDefaultsKey)
        }
    }

    func shouldDemoPilot(_ user: User) -> Bool {
        return primaryUserStorage.isPrimary(user) && !hasDemoedPilot
    }

    func didFinishPilotDemo(_ user: User) {
        if primaryUserStorage.isPrimary(user) {
            hasDemoedPilot = true
        }
    }

    private let demoDefaultsKey = "io.intrepid.MealTrackerPilot.hasDemoedPilot"

    private var hasDemoedPilot: Bool {
        get {
            return userDefaults.bool(forKey: demoDefaultsKey)
        }
        set {
            userDefaults.set(newValue, forKey: demoDefaultsKey)
        }
    }
}
