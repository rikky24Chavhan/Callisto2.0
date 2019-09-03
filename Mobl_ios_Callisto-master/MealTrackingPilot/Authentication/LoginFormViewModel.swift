//
//  LoginFormViewModel.swift
//  MealTrackingPilot
//
//  Created by Steve Galbraith on 7/16/18.
//  Copyright © 2018 Intrepid. All rights reserved.
//

import UIKit
import RxSwift


struct LoginFormViewModel {

    private struct Constants {
        static let defaultHelpText = "Enter in your user ID and password to sign in."
    }

    public enum LoginStatus: Equatable {
        case normal
        case error(Error)

        public static func == (lhs: LoginFormViewModel.LoginStatus, rhs: LoginFormViewModel.LoginStatus) -> Bool {
            switch (lhs, rhs) {
            case (.error(_), .error(_)), (.normal, .normal):
                return true
            default:
                return false
            }
        }
    }

    private var userCredentialStorage: LoginCredentialProviding
    var userID = Variable<String?>(nil)
    var password = Variable<String?>(nil)

    private var loginClient: LoginCredentialsLoginClient
    private(set) var currentStatus: Variable<LoginStatus> = Variable(.normal)
    var status: Observable<LoginStatus> {
        return currentStatus.asObservable()
    }

    var helpText: String {
        switch currentStatus.value {
        case .normal:
            return Constants.defaultHelpText
        case .error(let error):
            switch error {
            case APIClientError.httpError(let statusCode, _, _):
                if statusCode == 401 {
                    return "Incorrect user ID or password. Please try again."
                } else if statusCode == 404 {
                    return "We could not find an account with that user ID or it is linked to another device."
                } else {
                    return Constants.defaultHelpText
                }
            default:
                return Constants.defaultHelpText
            }
        }
    }

    var backgroundColor: UIColor {
        switch currentStatus.value {
        case .normal:
            return UIColor(white: 1, alpha: 0.2)
        case .error:
            return UIColor.piErrorBackground
        }
    }

    init(loginClient: LoginCredentialsLoginClient, userCredentialStorage: LoginCredentialProviding) {
        self.loginClient = loginClient
        self.userCredentialStorage = userCredentialStorage
        userID.value = userCredentialStorage.userLoginCredentials?.userName
    }

    mutating func login() {
        setLoginCredentials()
        loginClient.loginCredentials = userCredentialStorage.userLoginCredentials
        loginClient.login()
    }

    mutating func setStatus(_ status: LoginStatus) {
        currentStatus.value = status
    }

    // MARK: - Helper

    private mutating func setLoginCredentials() {
        let loginCredentials = PilotUserLoginCredentials(userName: userID.value, password: password.value)
        userCredentialStorage.userLoginCredentials = loginCredentials
    }
}
