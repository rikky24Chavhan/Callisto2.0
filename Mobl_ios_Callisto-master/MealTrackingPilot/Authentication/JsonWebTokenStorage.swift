//
//  JsonWebTokenStorage.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/16/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import APIClient

private let defaultTokenStorageKey = "json-web-token"

final class JsonWebTokenStorage: KeychainValueStorage<JsonWebToken>, AccessCredentialProviding {
    var accessCredentials: AccessCredentials? {
        get {
            return value
        }
        set {
            if let newToken = newValue, (newToken as? JsonWebToken) == nil {
                print("Error storing credentials: Expected JsonWebToken.")
                return
            }
            value = newValue as? JsonWebToken
        }
    }

    var expirationDate: Date? {
        return (accessCredentials as? JsonWebToken)?.expirationDate
    }

    init(tokenKey: String = defaultTokenStorageKey) {
        super.init(storageKey: tokenKey)
    }

    init(keychainServiceName: String, tokenKey: String = defaultTokenStorageKey) {
        super.init(keychainServiceName: keychainServiceName, storageKey: tokenKey)
    }
}
