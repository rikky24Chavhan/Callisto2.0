//
//  MockKeychain.swift
//  MealTrackingPilot
//
//  Created by Colden Prime on 5/19/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
@testable import MealTrackingPilot

class MockKeychain: KeychainDataStorage {
    private var storedData = [String: Data]()

    subscript(data key: String) -> Data? {
        get {
            return storedData[key]
        }
        set {
            storedData[key] = newValue
        }
    }
}
