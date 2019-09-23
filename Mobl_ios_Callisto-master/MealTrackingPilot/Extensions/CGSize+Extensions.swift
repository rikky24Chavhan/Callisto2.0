//
//  CGSize+Extensions.swift
//  MealTrackingPilot
//
//  Created by Gowtham on 23/09/19.
//  Copyright © 2019 Intrepid. All rights reserved.
//

import Foundation
import UIKit

extension CGSize {
    init(span: CGFloat, lateralSpan: CGFloat = 0, direction: ScrollingDirection) {
        let width = direction == .horizontal ? span : lateralSpan
        let height = direction == .vertical ? span : lateralSpan
        self.init(width: width, height: height)
    }
    
    func span(forDirection direction: ScrollingDirection) -> CGFloat {
        return direction == .horizontal ? width : height
    }
    
    func lateralSpan(forDirection direction: ScrollingDirection) -> CGFloat {
        return span(forDirection: direction.opposite())
    }
}
