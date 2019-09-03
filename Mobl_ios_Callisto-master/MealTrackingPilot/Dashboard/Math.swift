//
//  Math.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/27/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

func normalize(min: CGFloat, max: CGFloat, current: CGFloat) -> CGFloat {
    return (current - min) / (max - min)
}
