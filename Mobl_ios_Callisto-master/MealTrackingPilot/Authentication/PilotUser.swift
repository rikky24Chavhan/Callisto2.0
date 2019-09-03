//
//  PilotUser.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/14/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

struct PilotUser: User, Codable {
    var identifier: String
    var userName: String
    var installedDate: Date

    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case userName = "username"
        case installedDate = "inserted_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        userName = try container.decode(String.self, forKey: .userName)
        let dateString = try container.decode(String.self, forKey: .installedDate)
        if let timeInterval = TimeInterval(dateString) {
            installedDate = Date(timeIntervalSince1970: timeInterval)
        } else {
            installedDate = try DateFormatter.pilotDateFromString(dateString)
        }
    }

    init(identifier: String, userName: String, installedDate: Date) {
        self.identifier = identifier
        self.userName = userName
        self.installedDate = installedDate
    }
}
