//
//  JsonWebTokenStorageTests.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/17/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import KeychainAccess
import APIClient
@testable import MealTrackingPilot

final class JsonWebTokenStorageTests: XCTestCase {

    private let keychainServiceName = "io.intrepid.test.MealTrackingPilotTests"
    private lazy var storage1: JsonWebTokenStorage = JsonWebTokenStorage(keychainServiceName: self.keychainServiceName)
    private lazy var storage2: JsonWebTokenStorage = JsonWebTokenStorage(keychainServiceName: self.keychainServiceName)

    override func setUp() {
        clearKeychain()
        super.setUp()
    }

    override func tearDown() {
        clearKeychain()
        super.tearDown()
    }

    private func clearKeychain() {
        let keychain = Keychain(service: keychainServiceName)
        do {
            try keychain.removeAll()
        } catch (let error) {
            print("Could not clear keychain items: \(error)")
        }
    }

    func testStoringToken() {
        self.measure {
            let sut1 = self.storage1
            let sut2 = self.storage2

            let token = JsonWebToken(value: "TEST_TOKEN", expirationDate: Date(timeIntervalSince1970: 0))
            sut1.accessCredentials = token

            let retrievedToken1 = sut1.accessCredentials as? JsonWebToken
            XCTAssertEqual(retrievedToken1?.value, token.value, "Should retrieve correct token value from storage 1")
            XCTAssertEqual(retrievedToken1?.expirationDate, token.expirationDate, "Should retrieve correct token expiration date from storage 1")

            let retrievedToken2 = sut2.accessCredentials as? JsonWebToken
            XCTAssertEqual(retrievedToken2?.value, token.value, "Should retrieve correct token value from storage 2")
            XCTAssertEqual(retrievedToken2?.expirationDate, token.expirationDate, "Should retrieve correct token expiration date from storage 2")

            sut1.accessCredentials = nil
            XCTAssertNil(sut1.accessCredentials, "Should clear token from storage 1")
            XCTAssertNil(sut2.accessCredentials, "Should clear token from storage 2")
        }
    }

    func testStoringNonTokenCredentials() {
        let sut = storage1

        let credentials = MockNonTokenCredentials()
        sut.accessCredentials = credentials
        XCTAssertNil(sut.accessCredentials, "Should not store non-JWT credentials")
    }
}

fileprivate struct MockNonTokenCredentials: AccessCredentials {
    var expirationDate: Date?
    fileprivate func authorize(_ request: inout URLRequest) {}
}
