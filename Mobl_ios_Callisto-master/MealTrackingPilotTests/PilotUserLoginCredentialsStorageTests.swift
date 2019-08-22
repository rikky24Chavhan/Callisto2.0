//
//  PilotUserLoginCredentialsStorageTests.swift
//  MealTrackingPilotTests
//
//  Created by Steve Galbraith on 8/2/18.
//  Copyright © 2018 Intrepid. All rights reserved.
//

import XCTest
import KeychainAccess
@testable import MealTrackingPilot

class PilotUserLoginCredentialsStorageTests: XCTestCase {

    private let keychainServiceName = "io.intrepid.test.MealTrackingPilotTests"
    private lazy var storage1: PilotUserLoginCredentialsStorage = PilotUserLoginCredentialsStorage(keychainServiceName: self.keychainServiceName)
    private lazy var storage2: PilotUserLoginCredentialsStorage = PilotUserLoginCredentialsStorage(keychainServiceName: self.keychainServiceName)

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

    func testStoringCredentials() {
        self.measure {
            let userCredentials1 = PilotUserLoginCredentials(userName: "Participant99", password: "Password123")
            let userCredentials2 = PilotUserLoginCredentials(userName: "Participant01", password: "123Password")
            let sut1 = self.storage1
            let sut2 = self.storage2

            sut1.userLoginCredentials = userCredentials1

            let retrievedCredentials1 = sut1.userLoginCredentials as? PilotUserLoginCredentials
            XCTAssertEqual(retrievedCredentials1?.userName, userCredentials1.userName, "Should retrieve correct username from storage 1")
            XCTAssertEqual(retrievedCredentials1?.password, userCredentials1.password, "Should retrieve correct password from storage 1")

            sut2.userLoginCredentials = userCredentials2

            let retrievedCredentials2 = sut2.userLoginCredentials as? PilotUserLoginCredentials
            XCTAssertEqual(retrievedCredentials2?.userName, userCredentials2.userName, "Should retrieve correct username from storage 2")
            XCTAssertEqual(retrievedCredentials2?.password, userCredentials2.password, "Should retrieve correct password from storage 2")

            sut1.userLoginCredentials = nil
            XCTAssertNil(sut1.userLoginCredentials, "Should clear credentials from storage 1")
            XCTAssertNil(sut2.userLoginCredentials, "Should clear credentials from storage 2")
        }
    }
}
