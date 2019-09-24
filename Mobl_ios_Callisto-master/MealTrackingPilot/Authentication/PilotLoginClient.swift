//
//  JWTAuthenticationManager.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/8/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

protocol LoginClientUIDelegate: class {
    func presentLoginViewController()
    func dismissLoginViewControllers()
    func displayLoginError(for error: Error)
    func setShouldReload(_ value: Bool)
}

public protocol LoginClientDelegate: class {
    func loginClient(_ client: LoginClient, didFinishLoginWithResult result: Result<AccessCredentials,Error>)
    func loginClientDidDisconnect(_ client: LoginClient)
}

public protocol LoginClient {
    var delegate: LoginClientDelegate? { get set }
    func login()
    func logout()
    func refreshLogin(completion: accessCredentialsCompletion?)
}

protocol AccessCredentialsLoginClient: LoginClient {
    var accessCredentials: AccessCredentials? { get set }
    var uiDelegate: LoginClientUIDelegate? { get set }
}

protocol LoginCredentialsLoginClient: AccessCredentialsLoginClient {
    var loginCredentials: UserLoginCredentials? { get set }
}

public protocol AccessCredentials {
    var expirationDate: Date? { get set }
    func authorize(_ request: inout URLRequest)
}

public protocol AccessCredentialProviding {
    var accessCredentials: AccessCredentials? { get set }
}

enum PilotLoginError: Error {
    case unknownAuthCredentials
}

final class PilotLoginClient: AccessCredentialProviding, LoginUserProviding, LoginClientDelegate, LoginClientUIDelegate, AccessCredentialsLoginClient, LoginCredentialsLoginClient {
    var loginCredentials: UserLoginCredentials? {
        get {
            return loginCredentialsStorage.userLoginCredentials
        }
        set {
            if newValue as? PilotUserLoginCredentials != nil {
                loginCredentialsStorage.userLoginCredentials = newValue
            }
        }
    }
    public var accessCredentials: AccessCredentials? {
        get {
            return accessCredentialsStorage.accessCredentials
        }
        set {
            if newValue as? JsonWebToken != nil {
                accessCredentialsStorage.accessCredentials = newValue
            } else {
                accessCredentialsStorage.accessCredentials = nil
            }
        }
    }

    public var user: User? {
        get {
            return userStorage.user
        }
        set {
            if let newUser = newValue {
                primaryUserStorage.didLoginWithUser(newUser)
            }
            userStorage.user = newValue
        }
    }

    var isLoggedIn: Bool {
        return (accessCredentials != nil && user != nil)
    }

    private var refreshLoginCompletion: accessCredentialsCompletion?
    fileprivate typealias pilotLoginResponseCompletion = (Result<PilotLoginResponse,Error>) -> Void

    private let apiClient: APIClient
    private var accessCredentialsStorage: AccessCredentialProviding
    private var loginCredentialsStorage: LoginCredentialProviding
    private var userStorage: UserProviding
    private let primaryUserStorage: PrimaryUserStorage
    private let reachability: ReachabilityProtocol

    weak var delegate: LoginClientDelegate?
    weak var uiDelegate: LoginClientUIDelegate?

    init(
        apiClient: APIClient,
        accessCredentialsStorage: AccessCredentialProviding = JsonWebTokenStorage(),
        loginCredentialStorage: LoginCredentialProviding = PilotUserLoginCredentialsStorage(),
        userStorage: UserProviding = PilotUserKeychainStorage(storageKey: "current-user"),
        primaryUserStorage: PrimaryUserStorage,
        reachability: ReachabilityProtocol
    ) {
        self.apiClient = apiClient
        self.accessCredentialsStorage = accessCredentialsStorage
        self.loginCredentialsStorage = loginCredentialStorage
        self.userStorage = userStorage
        self.primaryUserStorage = primaryUserStorage
        self.reachability = reachability
    }

    func login() {

        guard let loginCredentials = loginCredentials else {
            logout()
            return
        }

        guard reachability.isConnectedToNetwork else { return }

        if let user = user {
            primaryUserStorage.didLoginWithUser(user)
        }
        uploadAuthCredentials(loginCredentials)
    }

    private func uploadAuthCredentials(_ credentials: LoginCredentials) {
        sendLoginRequest(credentials: credentials) { [weak self] result in
            guard let welf = self else {
                return
            }

            switch result {
                case .success(let response):
                    welf.setShouldReload(welf.accessCredentials == nil)
                    welf.accessCredentials = response.token
                    welf.user = response.user
                case .failure(let error):
                    print("Login error : \(error)")
                    welf.setShouldReload(welf.loginCredentials?.password != nil)
                    welf.refreshLoginCompletion = nil
                    welf.logout()
            }

            welf.handleLoginResult(result.map { $0.token })
        }
    }

    fileprivate func sendLoginRequest(credentials: LoginCredentials, completion: pilotLoginResponseCompletion?) {
        let request = PilotRequest.login(credentials: credentials).urlRequest
        apiClient.sendRequest(request, completion: completion)
    }

    private func handleLoginResult(_ result: Result<AccessCredentials,Error>) {
        switch result {
        case .success:
            if let refreshLoginCompletion = refreshLoginCompletion {
                refreshLoginCompletion(result)
                self.refreshLoginCompletion = nil
            } else {
                dismissLoginViewControllers()
                delegate?.loginClient(self, didFinishLoginWithResult: result)
            }
        case .failure(let error):
            displayLoginError(for: error)
            presentLoginViewController()
            delegate?.loginClient(self, didFinishLoginWithResult: result)
        }
    }

    func logout() {
        user = nil
        accessCredentials = nil
        loginCredentialsStorage.userLoginCredentials?.password = nil
        #if DEBUG
            clearPrimaryUser()
        #endif
    }

    func refreshLogin(completion: accessCredentialsCompletion? = nil) {
        guard let credentials = loginCredentials else {
            handleLoginResult(.failure(PilotLoginError.unknownAuthCredentials))
            return
        }

        refreshLoginCompletion = completion

        guard reachability.isConnectedToNetwork else { return }

        uploadAuthCredentials(credentials)
    }

    // MARK: - LoginClientDelegate

    func loginClient(_ client: LoginClient, didFinishLoginWithResult result: Result<AccessCredentials,Error>) {
        switch result {
        case .success(let accessCredentials):
            guard let accessCredentials = accessCredentials as? LoginCredentials else { return }
            uploadAuthCredentials(accessCredentials)
        case .failure:
            handleLoginResult(result)
        }
    }

    func loginClientDidDisconnect(_ client: LoginClient) {
        guard isLoggedIn else {
            // We weren't actually logged in, so no need to notify our delegate
            return
        }

        accessCredentials = nil
        user = nil

        DispatchQueue.main.async {
            self.delegate?.loginClientDidDisconnect(self)
        }
    }

    // MARK: LoginUserProviding

    func isLoggedInAsPrimaryUser() -> Bool {
        guard let user = user else {
            return false
        }
        return primaryUserStorage.isPrimary(user)
    }

    func clearPrimaryUser() {
        primaryUserStorage.clearPrimaryUser()
    }

    // MARK: LoginClientUIDelegate

    func presentLoginViewController() {
        uiDelegate?.presentLoginViewController()
    }

    func dismissLoginViewControllers() {
        uiDelegate?.dismissLoginViewControllers()
    }

    func displayLoginError(for error: Error) {
        uiDelegate?.displayLoginError(for: error)
    }

    func setShouldReload(_ value: Bool) {
        uiDelegate?.setShouldReload(value)
    }
}

fileprivate struct PilotLoginResponse: Codable {
    let user: PilotUser
    let token: JsonWebToken

    enum CodingKeys: String, CodingKey {
        case user
        case token = "credentials"
    }
}

extension Result {
     public func map<NewSuccess>(_ transform: (Success) -> NewSuccess) -> Result<NewSuccess, Failure>  {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }
}
