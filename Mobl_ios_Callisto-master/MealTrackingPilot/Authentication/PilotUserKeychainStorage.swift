//
//  PilotUserKeychainStorage.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/26/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import KeychainAccess

final class PilotUserKeychainStorage: KeychainValueStorage<PilotUser>, UserProviding {
    var user: User? {
        get {
            return value
        }
        set {
            if let user = newValue, (user as? PilotUser) == nil {
                print("Could not store user \(String(describing: user)): User is not a PilotUser")
                return
            }
            value = newValue as? PilotUser
        }
    }
}
