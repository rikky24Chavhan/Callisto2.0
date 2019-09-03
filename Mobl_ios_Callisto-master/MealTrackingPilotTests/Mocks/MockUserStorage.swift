//
//  MockUserStorage.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/30/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
@testable import MealTrackingPilot

final class MockUserStorage: UserProviding {
    var user: User?

    init(user: User? = nil) {
        self.user = user
    }
}
