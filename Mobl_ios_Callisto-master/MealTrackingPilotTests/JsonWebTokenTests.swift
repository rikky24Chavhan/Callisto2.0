//
//  JsonWebTokenTests.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/17/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest

@testable import MealTrackingPilot

final class JsonWebTokenTests: XCTestCase {

    lazy var fixtureJson: [String: Any] = {
        let bundle = Bundle(for: JsonWebTokenTests.self)
        let path = bundle.path(forResource: "test_json_web_token", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        return try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
    }()

    var validTokenJson: Data {
        let json = fixtureJson["valid_token"]!
        return try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    }

    var invalidTokenJson: Data {
        let json = fixtureJson["invalid_token"]!
        return try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    }

    var invalidExpirationDateJson: Data {
        let json = fixtureJson["invalid_expiration"]!
        return try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    }

    func testAuthorizeWithToken() {
        let token = JsonWebToken(value: "TEST_TOKEN", expirationDate: Date(timeIntervalSince1970: 0))
        let expectedHeaderKey = "Authorization"
        let expectedHeaderValue = "Bearer TEST_TOKEN"

        var request = URLRequest(url: URL(string: "notarealurl.test.com")!)
        token.authorize(&request)

        let authorizationHeader = request.allHTTPHeaderFields?.first(where: { headerField -> Bool in
            return headerField.key == expectedHeaderKey
        })

        XCTAssertNotNil(authorizationHeader, "Should add header with expected key")
        XCTAssertEqual(authorizationHeader?.value, expectedHeaderValue, "Should add header with expected value")
    }

    func testInitFromValidJson() {
        let token = try? JsonWebToken(data: validTokenJson)
        XCTAssertEqual(token?.value, "TEST_TOKEN", "Should initialize with correctly mapped value")
        XCTAssertEqual(token?.expirationDate, Date(timeIntervalSince1970: 1337), "Should initialize with correctly mapped expiration date")
    }

    func testInitFromInvalidJson() {
        var error: Error? = nil

        do {
            _ = try JsonWebToken(data: invalidTokenJson)
        } catch (let err) {
            error = err
        }

        XCTAssertNotNil(error, "Should throw mapping error")
    }

    func testInitFromInvalidExpirationDateJson() {
        var errorThrown = false

        do {
            _ = try JsonWebToken(data: invalidExpirationDateJson)
        } catch JsonWebTokenParseError.invalidExpirationTimestamp {
            errorThrown = true
        } catch {

        }

        XCTAssert(errorThrown, "Should throw invalid expiration timestamp error")
    }
}
