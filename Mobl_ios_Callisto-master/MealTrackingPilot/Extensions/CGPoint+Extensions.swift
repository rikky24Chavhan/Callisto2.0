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
    
}
