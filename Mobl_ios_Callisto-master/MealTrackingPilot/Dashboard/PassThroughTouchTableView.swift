//
//  PassThroughTouchTableView.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/27/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

public class PassThroughTouchTableView: UITableView {

    var passThroughViews: [UIView] = []

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if result == self {
            for view in passThroughViews {
                let point = view.convert(point, from: self)
                if let hit = view.hitTest(point, with: event) {
                    return hit
                }
            }
        }
        return result
    }
}
