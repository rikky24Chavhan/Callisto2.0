//
//  KeychainDataStorage.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 5/3/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import KeychainAccess

protocol KeychainDataStorage {
    subscript(data key: String) -> Data? { get set }
}

extension Keychain: KeychainDataStorage {}
