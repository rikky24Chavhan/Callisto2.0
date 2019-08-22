//
//  Array+Extensions.swift
//  MealTrackingPilot
//
//  Created by Litteral, Maximilian on 10/4/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {

    mutating func removeObject(_ object: Element) {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
    }

    func removingObjectsInArray(_ array: [Element]) -> [Element] {
        var copy = self
        for object in array {
            copy.removeObject(object)
        }
        return copy
    }
}
