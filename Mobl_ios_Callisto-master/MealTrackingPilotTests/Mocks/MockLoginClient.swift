//
//  MockLoginClient.swift
//  MealTrackingPilot
//
//  Created by Colden Prime on 5/19/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//


@testable import MealTrackingPilot

class MockLoginClient: LoginCredentialsLoginClient {
    var loginCredentials: UserLoginCredentials?
    var accessCredentials: AccessCredentials?
    var delegate: LoginClientDelegate?
    var uiDelegate: LoginClientUIDelegate?

    var functionCalls = [String]()

    func login() {
        functionCalls.append("login")
    }

    func logout() {
        functionCalls.append("logout")
    }

    func refreshLogin(completion: ((Result<AccessCredentials,Error>) -> Void)?) {
        functionCalls.append("refreshLogin")
    }
}
