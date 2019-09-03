//
//  MockLoginUserProvider.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/30/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
@testable import MealTrackingPilot

final class MockLoginUserProvider: LoginUserProviding {
    var user: User?
    var mockIsLoggedInAsPrimaryUser: Bool = false

    init(user: User? = nil, mockIsLoggedInAsPrimaryUser: Bool = false) {
        self.user = user
        self.mockIsLoggedInAsPrimaryUser = mockIsLoggedInAsPrimaryUser
    }

    func isLoggedInAsPrimaryUser() -> Bool {
        return mockIsLoggedInAsPrimaryUser
    }
}
