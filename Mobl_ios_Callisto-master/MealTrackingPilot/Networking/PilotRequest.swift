//
//  PilotRequest.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/14/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import APIClient

struct PilotRequest: Request {
    // MARK: - Request

    #if DEBUG
    static var baseURL = "https://callisto.lilly.com"
    #else
    static var baseURL = "https://callisto.lilly.com"
    #endif

    static var acceptHeader: String? = "application/json; version=1"

    var method: HTTPMethod
    var path: String
    var authenticated: Bool

    var queryParameters: [String : Any]?
    var bodyParameters: [String : Any]?

    var contentType: String
    var accessCredentials: AccessCredentials?

    init(
        method: HTTPMethod,
        path: String,
        authenticated: Bool = true,
        queryParameters: [String: Any]? = nil,
        bodyParameters: [String: Any]? = nil,
        contentType: String = "application/json",
        accessCredentials: AccessCredentials? = nil
    ) {
        self.method = method
        self.path = path
        self.authenticated = authenticated
        self.queryParameters = queryParameters
        self.bodyParameters = bodyParameters
        self.contentType = contentType
        self.accessCredentials = accessCredentials
    }
}
