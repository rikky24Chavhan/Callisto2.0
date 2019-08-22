//
//  LoginFormViewModelTests.swift
//  MealTrackingPilotTests
//
//  Created by Steve Galbraith on 8/2/18.
//  Copyright © 2018 Intrepid. All rights reserved.
//

import XCTest
import KeychainAccess
import APIClient
@testable import MealTrackingPilot

class LoginFormViewModelTests: XCTestCase {
    private let keychainServiceName = "io.intrepid.test.MealTrackingPilotTests"
    private lazy var mockUserCredentialStorage = PilotUserLoginCredentialsStorage(keychainServiceName: self.keychainServiceName)
    let mockLoginClient = MockLoginClient()
    
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
    
    func testPropertiesForNormalStatus() {
        var viewModel = LoginFormViewModel(loginClient: mockLoginClient, userCredentialStorage: mockUserCredentialStorage)
        viewModel.setStatus(.normal)

        XCTAssertEqual(viewModel.helpText, "Enter in your user ID and password to sign in.")
        XCTAssertEqual(viewModel.backgroundColor, UIColor(white: 1.0, alpha: 0.2))
    }

    func testPropertiesForErrorStatus() {
        let errorResponse = HTTPURLResponse(url: URL(string: "https://www.google.com")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        var viewModel = LoginFormViewModel(loginClient: mockLoginClient, userCredentialStorage: mockUserCredentialStorage)

        // Incorrect login information
        let incorrectLoginError = APIClientError.httpError(statusCode: 401, response: errorResponse, data: nil)
        viewModel.setStatus(.error(incorrectLoginError))

        XCTAssertEqual(viewModel.helpText, "Incorrect user ID or password. Please try again.")
        XCTAssertEqual(viewModel.backgroundColor, UIColor.piErrorBackground)

        // User has been deleted
        let notFoundError = APIClientError.httpError(statusCode: 404, response: errorResponse, data: nil)
        viewModel.setStatus(.error(notFoundError))

        XCTAssertEqual(viewModel.helpText, "We could not find an account with that user ID or it is linked to another device.")
        XCTAssertEqual(viewModel.backgroundColor, UIColor.piErrorBackground)
    }

    func testLogin() {
        let userName = "Participant99"
        let password = "Password123"
        let storage = mockUserCredentialStorage
        let loginClient = mockLoginClient
        var viewModel = LoginFormViewModel(loginClient: loginClient, userCredentialStorage: storage)

        XCTAssertNil(storage.userLoginCredentials)
        XCTAssert(loginClient.functionCalls.isEmpty)

        viewModel.userID.value = userName
        viewModel.password.value = password
        viewModel.login()

        XCTAssertNotNil(storage.userLoginCredentials)
        XCTAssertEqual(storage.userLoginCredentials?.userName, userName)
        XCTAssertEqual(storage.userLoginCredentials?.password, password)
        XCTAssertEqual(loginClient.functionCalls, ["login"])
    }
}
