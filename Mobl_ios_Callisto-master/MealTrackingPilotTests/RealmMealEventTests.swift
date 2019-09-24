//
//  RealmMealEventTests.swift
//  MealTrackingPilot
//
//  Created by Colden Prime on 5/30/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import RealmSwift
@testable import MealTrackingPilot

class RealmMealEventTests: XCTestCase {

    let realmConfiguration = Realm.Configuration(inMemoryIdentifier: "RealmMealDataControllerTests-\(UUID())")

    lazy var realm: Realm = {
        return try! Realm(configuration: self.realmConfiguration)
    }()

    override func tearDown() {
        try! realm.write {
            realm.deleteAll()
        }

        super.tearDown()
    }

    func testLocalFileImageURL() {
        let sut = RealmMealEvent()
        let fileName = "test.jpeg"
        sut.imageURL = MockFileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
        XCTAssertNil(sut.imageURLString)
        XCTAssertEqual(sut.localImageFileName, fileName)
    }

    func testRemoteImageURL() {
        let sut = RealmMealEvent()
        let path = "http://www.intrepid.io/hs-fs/hubfs/Intrepid_Mar2016/nav_bg-8e68a1795ce5f354797aad6e45b566b9.png?t=1489432679175&width=5779&name=nav_bg-8e68a1795ce5f354797aad6e45b566b9.png"
        sut.imageURL = URL(string: path)
        XCTAssertNil(sut.localImageFileName)
        XCTAssertEqual(sut.imageURLString, path)
    }

    func testCopyIsUnmanaged() {
        let sut = RealmMealEvent()
        sut.localIdentifier = "test-identifier"
        try! realm.write {
            realm.add(sut, update: true)
        }

        XCTAssertNotNil(sut.realm)

        guard let sutCopy = sut.copy() as? RealmMealEvent else {
            XCTFail("Failed to create RealmMealEvent copy")
            return
        }
        XCTAssertNil(sutCopy.realm)
    }
}
