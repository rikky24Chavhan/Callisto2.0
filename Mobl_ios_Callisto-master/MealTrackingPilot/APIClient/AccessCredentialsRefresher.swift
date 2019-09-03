//
//  AuthTokenRefresher.swift
//  APIClient
//
//  Created by Mark Daigneault on 3/3/17.
//  Copyright © 2017 Mark Daigneault. All rights reserved.
//

import Foundation

public enum AccessCredentialsRefresherError: Error {
    case MissingCredentials
    case AuthenticationError(Error)
}

public class AccessCredentialsRefresher {

    let apiClient: APIClient
    let loginClient: LoginClient
    var accessCredentialsProvider: AccessCredentialProviding

    public init(apiClient: APIClient, loginClient: LoginClient, accessCredentialsProvider: AccessCredentialProviding) {
        self.apiClient = apiClient
        self.loginClient = loginClient
        self.accessCredentialsProvider = accessCredentialsProvider
    }

    func handleUnauthorizedRequest(request: URLRequest, completion: defaultRequestCompletion?) {
        loginClient.refreshLogin { [weak self] result in
            guard let completion = completion, let welf = self else { return }
            switch result {
                case .success(let accessCredentials):
                    var mutableRequest = request
                    welf.accessCredentialsProvider.accessCredentials = accessCredentials
                    accessCredentials.authorize(&mutableRequest)
                    welf.apiClient.sendRequest(mutableRequest, completion: completion)
                case .failure(let error):
                    welf.accessCredentialsProvider.accessCredentials = nil
                    completion(.failure(AccessCredentialsRefresherError.AuthenticationError(error)))
            }
        }
    }
}
