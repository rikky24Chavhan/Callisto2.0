//
//  CGPoint+Extension.swift
//  CarouselView
//
//  Created by Rikky Chavhan on 20/08/19.
//  Copyright © 2019 L&T. All rights reserved.
//

import Foundation
import UIKit

 extension CGPoint {
   
    public static func += (left: inout CGPoint, right: CGPoint) {
        left.x += right.x
        left.y += right.y
    }
    
    public static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    
    public static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    public static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    init (offset: CGFloat, lateralOffset: CGFloat = 0, direction: ScrollingDirection) {
        let x = direction == .horizontal ? offset : lateralOffset
        let y = direction == .vertical ? offset : lateralOffset
        self.init(x: x, y: y)
    }
    
    func offset(forDirection direction: ScrollingDirection) -> CGFloat {
        return direction == .horizontal ? x : y
    }
    
    mutating func setOffset(_ offset: CGFloat, forDirection direction: ScrollingDirection) {
        switch direction {
        case .horizontal:
            x = offset
            break
        case .vertical:
            y = offset
            break
        }
    }
}
