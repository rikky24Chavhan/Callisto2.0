//
//  KeychainValueStorage.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/28/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

import KeychainAccess

class KeychainValueStorage<T: Codable> {
    typealias Value = T

    var value: Value? {
        get {
            do {
                return try readValue()
            } catch(let error) {
                print("Error reading value of type \(Value.self) from keychain: \(error)")
                return nil
            }
        }
        set {
            guard let assignedValue = newValue else {
                deleteValue()
                return
            }

            do {
                try writeValue(assignedValue)
            } catch(let error) {
                print("Error writing value to keychain: \(error)")
            }
        }
    }

    var shouldDeleteOnFirstLaunch: Bool {
        return true
    }

    // MARK: - Keychain Storage

    private let keychainServiceName: String
    private let storageKey: String

    private let encoder = JSONEncoder.CallistoJSONEncoder()
    private let decoder = JSONDecoder.CallistoJSONDecoder()

    private lazy var keychainItem: Keychain = Keychain(service: self.keychainServiceName)

    init(keychainServiceName: String = "io.intrepid.MealTrackingPilot", storageKey: String) {
        self.keychainServiceName = keychainServiceName
        self.storageKey = storageKey
    }

    private func readValue() throws -> Value? {
        guard let storedData = keychainItem[data: storageKey] else {
            return nil
        }
        return try decoder.decode(T.self, from: storedData)
    }

    private func writeValue(_ newValue: Value) throws {
        let data = try encoder.encode(newValue)
        keychainItem[data: storageKey] = data
    }

    private func deleteValue() {
        keychainItem[data: storageKey] = nil
    }
}
