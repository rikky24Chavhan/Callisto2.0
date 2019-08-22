//
//  RealmObjectIDGenerator.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/6/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

class RealmObjectIDGenerator {
    class func localIdentifier() -> String {
        return UUID().uuidString.lowercased()
    }
}
