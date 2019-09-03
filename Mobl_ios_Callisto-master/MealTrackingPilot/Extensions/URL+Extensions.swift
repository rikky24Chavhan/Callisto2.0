//
//  URL+Extensions.swift
//  MealTrackingPilot
//
//  Created by Colden Prime on 6/2/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

extension URL {
    var withoutQueryComponents: URL? {
        var imageURLComponents = URLComponents(url: self, resolvingAgainstBaseURL: false)
        imageURLComponents?.query = nil
        return imageURLComponents?.url
    }
}
