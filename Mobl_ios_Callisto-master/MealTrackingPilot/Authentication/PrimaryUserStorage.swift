//
//  PrimaryUserStorage.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/29/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

protocol PrimaryUserStorage {
    func didLoginWithUser(_ user: User)
    func isPrimary(_ user: User) -> Bool
    func clearPrimaryUser()
}

final class PilotPrimaryUserStorage: PrimaryUserStorage {
    private var underlyingUserProvider: UserProviding

    init(underlyingUserProvider: UserProviding = PilotUserKeychainStorage(storageKey: "primary-user")) {
        self.underlyingUserProvider = underlyingUserProvider
    }

    func didLoginWithUser(_ user: User) {
        if let _ = underlyingUserProvider.user {
            return
        }
        underlyingUserProvider.user = user
    }

    func isPrimary(_ user: User) -> Bool {
        guard let primaryUser = underlyingUserProvider.user else {
            return false
        }
        return primaryUser.identifier == user.identifier
    }

    func clearPrimaryUser() {
        underlyingUserProvider.user = nil
    }
}
