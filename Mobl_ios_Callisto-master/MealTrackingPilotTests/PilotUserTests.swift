//
//  PilotUserTests.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 5/9/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
@testable import MealTrackingPilot

final class PilotUserTests: XCTestCase {
    func testParseUser() {
        let mockLoginResponse: Data = {
            let object = [
                "updated_at": "2017-03-02T21:48:35.579741Z",
                "inserted_at": "2017-03-02T21:48:35.00000Z",
                "id": "1dabcbbe-d2ce-4091-9d30-199d6ae833ad",
                "google_id": "12345abcde",
                "username": "Participant99"
            ]
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode(object)
        }()

        do {
            let decoder = JSONDecoder.CallistoJSONDecoder()
            let user = try decoder.decode(PilotUser.self, from: mockLoginResponse)
            XCTAssertEqual(user.userName, "Participant99")
            XCTAssertEqual(user.identifier, "1dabcbbe-d2ce-4091-9d30-199d6ae833ad")
            XCTAssertEqual(user.installedDate.timeIntervalSince1970, 1488491315.0)
        } catch {
            XCTFail("Failed to parse user")
        }
    }
}
