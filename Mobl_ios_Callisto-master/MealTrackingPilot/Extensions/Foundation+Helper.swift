//
//  Foundation+Helper.swift
//  MealTrackingPilot
//
//  Created by sugapriya on 09/09/19.
//  Copyright © 2019 Intrepid. All rights reserved.
//

import Foundation

public typealias Block = () -> ()

public func After(_ after: TimeInterval, on queue: DispatchQueue = .main, op: @escaping Block) {
    let seconds = Int64(after * Double(NSEC_PER_SEC))
    let dispatchTime = DispatchTime.now() + Double(seconds) / Double(NSEC_PER_SEC)
    queue.asyncAfter(deadline: dispatchTime, execute: op)
}
