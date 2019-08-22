//
//  RealmSeeder.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/23/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import RealmSwift

class RealmSeeder {
    enum JsonError: Error {
        case couldNotFindTopLevelMealEvents
        case couldNotFindTopLevelMeals
    }

    class func seedRealm() {
        do {
            let realm = try Realm(configuration: Realm.Configuration(deleteRealmIfMigrationNeeded: true))
            seedRealm(realm: realm)
        } catch (let error) {
            print("Could not seed Realm: \(error)")
        }
    }

    class func seedRealm(realm: Realm) {
        do {
            let bundle = Bundle.main
            let path = bundle.path(forResource: "seed", ofType: "json")!
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let mealEvents = try [RealmMealEvent](data: data, keyPath: "meal_events")

            try realm.write {
                realm.deleteAll()
                realm.add(mealEvents, update: true)
            }
        } catch (let error) {
            print("Could not seed Realm: \(error)")
        }
    }
}
