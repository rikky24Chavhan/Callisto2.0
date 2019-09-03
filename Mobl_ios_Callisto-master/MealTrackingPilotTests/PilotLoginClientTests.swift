//
//  PilotLoginClientTests.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/9/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import Intrepid

@testable import MealTrackingPilot

class PilotLoginClientTests: XCTestCase {

    private let expectedHTTPBody: Data = {
        let object = [
            "username": "Participant99",
            "password": "Password123",
            "device_id": "D9F0A23B-E5B0-4509-9F31-B37F2FB131C1"
        ]
        return try! JSONSerialization.data(withJSONObject: object, options: [])
    }()

    private var credentials: UserLoginCredentials {
        let userName = "Participant99"
        let password = "Password123"
        return PilotUserLoginCredentials(userName: userName, password: password)
    }

    func testSuccessfulSignIn() {
        let mockLoginResponse: Data = {
            let object = [
                "user": [
                    "updated_at": "2017-03-02T21:48:35.579741Z",
                    "inserted_at": "2017-03-02T21:48:35.574107Z",
                    "id": "1dabcbbe-d2ce-4091-9d30-199d6ae833ad",
                    "username": "Participant99",
                    "device_id": "D9F0A23B-E5B0-4509-9F31-B37F2FB131C1"
                ],
                "credentials": [
                    "token": "TEST_RESULT_TOKEN",
                    "expires_at": "1488908189"
                ]
            ]
            return try! JSONSerialization.data(withJSONObject: object, options: [])
        }()

        let apiClient = MockResponseAPIClient(mockResult: .success(mockLoginResponse))

        let asyncExpectation = expectation(description: "Async sign-in operation")
        let delegate = MockLoginClientDelegate()
        delegate.loginCompletion = { _ in
            asyncExpectation.fulfill()
        }

        let sut = PilotLoginClient(
            apiClient: apiClient,
            accessCredentialsStorage: MockTokenStorage(),
            userStorage: MockUserStorage(),
            primaryUserStorage: PilotPrimaryUserStorage(underlyingUserProvider: MockUserStorage()),
            reachability: MockReachability()
        )
        sut.delegate = delegate

        sut.loginCredentials = credentials

        XCTAssertFalse(sut.isLoggedIn, "Should not be logged in.")

        sut.login()

        waitForExpectations(timeout: 1) { [weak self] error in
            XCTAssertNil(error)

            guard let welf = self else { return }

            // TODO: Test expected request URL
            XCTAssertEqual(apiClient.requestSent?.httpBody, welf.expectedHTTPBody, "Should send correct request body.")

            let token = (delegate.loginResult?.value as? JsonWebToken)
            XCTAssertEqual(token?.value, "TEST_RESULT_TOKEN", "Did receive logged in user response with correct token.")

            XCTAssert(sut.isLoggedIn, "Should be logged in")
            XCTAssertEqual(sut.user?.identifier, "1dabcbbe-d2ce-4091-9d30-199d6ae833ad", "Should store user from response")
            XCTAssertEqual((sut.accessCredentials as? JsonWebToken)?.value, "TEST_RESULT_TOKEN", "Should store token")
        }
    }

    func testFailedSignIn() {
        let mockError = NSError(domain: "TEST_ERROR", code: 1337, userInfo: [:])

        let apiClient = MockResponseAPIClient(mockResult: .failure(mockError))

        let asyncExpectation = expectation(description: "Async sign-in operation")
        let delegate = MockLoginClientDelegate()
        delegate.loginCompletion = { _ in
            asyncExpectation.fulfill()
        }

        let sut = PilotLoginClient(
            apiClient: apiClient,
            accessCredentialsStorage: MockTokenStorage(),
            userStorage: MockUserStorage(),
            primaryUserStorage: PilotPrimaryUserStorage(underlyingUserProvider: MockUserStorage()),
            reachability: MockReachability()
        )
        sut.delegate = delegate

        sut.loginCredentials = credentials

        XCTAssertFalse(sut.isLoggedIn, "Should not be logged in.")

        sut.login()

        waitForExpectations(timeout: 1) { [weak self] error in
            XCTAssertNil(error)

            guard let welf = self else { return }

            // TODO: Test expected request URL
            XCTAssertEqual(apiClient.requestSent?.httpBody, welf.expectedHTTPBody, "Did send correct request body.")
            XCTAssertNotNil(delegate.loginResult?.error, "Did convey error to delegate.")

            XCTAssertFalse(sut.isLoggedIn, "Should not be logged in")
            XCTAssertNil(sut.user, "Should have no stored user")
        }
    }

    func testPrimaryUserLogin() {
        let apiClient = MockPilotAPIClient()
        let accessCredentialStorage = MockTokenStorage()
        let userStorage = MockUserStorage()
        let primaryUserStorage = MockUserStorage()
        let reachability = MockReachability()

        let sut = PilotLoginClient(
            apiClient: apiClient,
            accessCredentialsStorage: accessCredentialStorage,
            userStorage: userStorage,
            primaryUserStorage: PilotPrimaryUserStorage(underlyingUserProvider: primaryUserStorage),
            reachability: reachability
        )

        let user1 = PilotUser(identifier: "mock-user-1", userName: "Participant98", installedDate: Date())
        let user2 = PilotUser(identifier: "mock-user-2", userName: "Participant99", installedDate: Date())

        XCTAssertFalse(sut.isLoggedIn, "Should not be logged in")
        XCTAssertFalse(sut.isLoggedInAsPrimaryUser(), "Should not be logged in as primary user")

        // Mock a login (without the full async flow)
        // TODO: Consider rewriting this test to queue up multiple async logins
        userStorage.user = user1
        accessCredentialStorage.accessCredentials = MockAccessCredentials()
        sut.login()

        XCTAssert(sut.isLoggedIn, "Should be logged in")
        XCTAssert(sut.isLoggedInAsPrimaryUser(), "Should be logged in as primary user")

        // Mock a logout
        userStorage.user = nil
        accessCredentialStorage.accessCredentials = nil

        XCTAssertFalse(sut.isLoggedIn, "Should not be logged in")
        XCTAssertFalse(sut.isLoggedInAsPrimaryUser(), "Should not be logged in as primary user")

        // Mock login as a second user
        userStorage.user = user2
        accessCredentialStorage.accessCredentials = MockAccessCredentials()
        sut.login()

        XCTAssert(sut.isLoggedIn, "Should be logged in")
        XCTAssertFalse(sut.isLoggedInAsPrimaryUser(), "Should not be logged in as primary user")

        // Mock a logout
        userStorage.user = nil
        accessCredentialStorage.accessCredentials = nil

        XCTAssertFalse(sut.isLoggedIn, "Should not be logged in")
        XCTAssertFalse(sut.isLoggedInAsPrimaryUser(), "Should not be logged in as primary user")

        // Mock login as the original user
        userStorage.user = user1
        accessCredentialStorage.accessCredentials = MockAccessCredentials()
        sut.login()

        XCTAssert(sut.isLoggedIn, "Should be logged in")
        XCTAssert(sut.isLoggedInAsPrimaryUser(), "Should be logged in as primary user")
    }

    func testLoginWithNoConnection() {
        let mockError = NSError(domain: "TEST_ERROR", code: 1337, userInfo: [:])
        let apiClient = MockResponseAPIClient(mockResult: .failure(mockError))

        let userStorage = MockUserStorage()

        let sut = PilotLoginClient(
            apiClient: apiClient,
            accessCredentialsStorage: MockTokenStorage(),
            userStorage: userStorage,
            primaryUserStorage: PilotPrimaryUserStorage(underlyingUserProvider: MockUserStorage()),
            reachability: MockReachability(isConnected: false)
        )
        sut.delegate = MockLoginClientDelegate()

        // User has logged in before and has credentials stored
        sut.loginCredentials = credentials
        sut.accessCredentials = JsonWebToken(value: "some_previous_token")
        userStorage.user = PilotUser(identifier: "mock-user", userName: "Participant99", installedDate: Date())

        XCTAssert(sut.isLoggedIn, "Should be logged in")

        sut.login()

        // User does not fail authentication and get logged out
        XCTAssert(sut.isLoggedIn, "Should still be logged in")
    }
}

// MARK: - Mocks

fileprivate final class MockAccessCredentialsLoginClient: AccessCredentialsLoginClient {
    var accessCredentials: AccessCredentials?
    var delegate: LoginClientDelegate?
    var uiDelegate: LoginClientUIDelegate?
    var authResult: Result<AccessCredentials>?

    fileprivate func login() {
        guard let result = authResult else {
            return
        }
        delegate?.loginClient(self, didFinishLoginWithResult: result)
    }

    fileprivate func login(with credentials: AccessCredentials) {
        guard let result = authResult else {
            return
        }
        delegate?.loginClient(self, didFinishLoginWithResult: result)
    }

    fileprivate func logout() {
        After(0.1, on: .global(qos: .background)) {
            self.delegate?.loginClientDidDisconnect(self)
        }
    }

    fileprivate func handleRedirectURL(url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return true
    }

    fileprivate func refreshLogin(completion: ((Result<AccessCredentials>) -> Void)?) {
        login()
    }
}

fileprivate final class MockResponseAPIClient: APIClient {
    var requestSent: URLRequest?
    var mockResult: Result<Data?>

    init(mockResult: Result<Data?>) {
        self.mockResult = mockResult
        super.init(session: .shared, decoder: JSONDecoder.CallistoJSONDecoder())
    }

    fileprivate override func sendRequest(_ request: URLRequest, completion: ((Result<Data?>) -> Void)?) {
        requestSent = request
        completion?(mockResult)
    }
}

fileprivate final class MockLoginClientDelegate: LoginClientDelegate {
    var loginCompletion: ((Result<AccessCredentials>) -> Void)?
    var logoutCompletion: (() -> Void)?
    var loginResult: Result<AccessCredentials>?

    fileprivate func loginClient(_ client: LoginClient, didFinishLoginWithResult result: Result<AccessCredentials>) {
        loginResult = result
        loginCompletion?(result)
    }

    fileprivate func loginClientDidDisconnect(_ client: LoginClient) {
        logoutCompletion?()
    }
}

fileprivate final class MockTokenStorage: AccessCredentialProviding {
    fileprivate var accessCredentials: AccessCredentials?

    init(credentials: AccessCredentials? = nil) {
        self.accessCredentials = credentials
    }
}

fileprivate struct MockAccessCredentials: AccessCredentials {
    var expirationDate: Date?
    func authorize(_ request: inout URLRequest) {}
}

fileprivate final class MockReachability: ReachabilityProtocol {
    var isConnectedToNetwork: Bool

    init(isConnected: Bool = true) {
        self.isConnectedToNetwork = isConnected
    }
}
