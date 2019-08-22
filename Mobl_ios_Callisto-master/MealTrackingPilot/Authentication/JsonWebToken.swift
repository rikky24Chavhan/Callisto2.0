//
//  JsonWebToken.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/14/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import APIClient

enum JsonWebTokenParseError: Error {
    case invalidExpirationTimestamp
}

struct JsonWebToken: AccessCredentials, Codable {
    let value: String
    var expirationDate: Date?

    enum CodingKeys: String, CodingKey {
        case value = "token"
        case expirationDate = "expires_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
        if let timeInterval = expirationDate?.timeIntervalSince1970 {
            try container.encode("\(timeInterval)", forKey: .expirationDate)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try container.decode(String.self, forKey: .value)
        let timeIntervalString = try container.decode(String.self, forKey: .expirationDate)
        if let timeInterval = TimeInterval(timeIntervalString) {
            expirationDate = Date(timeIntervalSince1970: timeInterval)
        } else {
            throw JsonWebTokenParseError.invalidExpirationTimestamp
        }
    }

    init(value: String, expirationDate: Date? = nil) {
        self.value = value
        self.expirationDate = expirationDate
    }

    func authorize(_ request: inout URLRequest) {
        let formattedValue = "Bearer \(value)"
        request.setValue(formattedValue, forHTTPHeaderField: "Authorization")
    }
}

