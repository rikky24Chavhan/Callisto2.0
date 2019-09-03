//
//  TestMealEventProvider.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/20/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
@testable import MealTrackingPilot

struct TestMealEventProvider {

    static func getCommonMealEvent() throws -> MealEvent {
        return try parseFileNamed("common_meal_event", to: RealmMealEvent.self)
    }

    static func getTestMealEvent() throws -> MealEvent {
        return try parseFileNamed("test_meal_event", to: RealmMealEvent.self)
    }

    static func getNullMappingsMealEvent() throws -> MealEvent {
        return try parseFileNamed("meal_event_null_mappings", to: RealmMealEvent.self)
    }

    static func expectedCommonMealEventPostJson() -> [String: Any] {
        let data = jsonDataFromFileName("common_meal_event_post")
        return try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
    }

    static func expectedTestMealEventPostJson() -> [String: Any] {
        let data = jsonDataFromFileName("test_meal_event_post")
        return try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
    }
}

fileprivate func parseFileNamed<T: Codable>(_ name: String, to type: T.Type) throws -> T {
    let data = jsonDataFromFileName(name)
    let decoder = JSONDecoder.CallistoJSONDecoder()
    return try decoder.decode(T.self, from: data)
}

fileprivate func jsonDataFromFileName(_ name: String) -> Data {
    let bundle = Bundle(for: MealEventTests.self)
    let path = bundle.path(forResource: name, ofType: "json")!
    return try! Data(contentsOf: URL(fileURLWithPath: path))
}
