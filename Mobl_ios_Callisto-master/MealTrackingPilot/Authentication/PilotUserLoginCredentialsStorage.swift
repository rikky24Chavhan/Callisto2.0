//
//  PilotUserLoginCredentialsStorage.swift
//  MealTrackingPilot
//
//  Created by Steve Galbraith on 8/1/18.
//  Copyright © 2018 Intrepid. All rights reserved.
//

import Foundation
import APIClient

protocol LoginCredentialProviding {
    var userLoginCredentials: UserLoginCredentials? { get set }
}

private let defaultTokenStorageKey = "login-credentials"

final class PilotUserLoginCredentialsStorage: KeychainValueStorage<PilotUserLoginCredentials>, LoginCredentialProviding {
    var userLoginCredentials: UserLoginCredentials? {
        get {
            return value
        }
        set {
            if let newToken = newValue, (newToken as? PilotUserLoginCredentials) == nil {
                print("Error storing credentials: Expected UserLoginCredentials.")
                return
            }
            value = newValue as? PilotUserLoginCredentials
        }
    }

    init(tokenKey: String = defaultTokenStorageKey) {
        super.init(storageKey: tokenKey)
    }
    
    init(keychainServiceName: String, tokenKey: String = defaultTokenStorageKey) {
        super.init(keychainServiceName: keychainServiceName, storageKey: tokenKey)
    }
}
