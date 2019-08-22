//
//  RealmSynchronizable.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 5/1/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import RealmSwift

public class RealmSynchronizable: RealmSwift.Object, Synchronizable {

    @objc dynamic var identifier: String = ""
    @objc dynamic var localIdentifier: String = ""
    @objc dynamic var createdDate: Date = Date()
    @objc dynamic var updatedDate: Date = Date()
    @objc dynamic var isDirty: Bool = false

    // MARK: - Realm

    override public class func primaryKey() -> String? {
        return "localIdentifier"
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case localIdentifier = "client_id"
        case createdDate = "inserted_at"
        case updatedDate = "updated_at"
    }

    func decode(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        localIdentifier = try container.decodeIfPresent(String.self, forKey: .localIdentifier) ?? ""
        createdDate = try container.decodeCallistoDate(forKey: .createdDate)
        updatedDate = try container.decodeCallistoDate(forKey: .updatedDate)
    }
}
