//
//  Geometry+Extensions.swift
//  MealTrackingPilot
//
//  Created by sugapriya on 09/09/19.
//  Copyright © 2019 Intrepid. All rights reserved.
//

import Foundation
import UIKit

public extension CGRect {
    
    var topLeft: CGPoint {
        return CGPoint(x: minX, y: minY)
    }
    
    var topRight: CGPoint {
        return CGPoint(x: maxX, y: minY)
    }
    
    var bottomRight: CGPoint {
        return CGPoint(x: maxX, y: maxY)
    }
    
    var bottomLeft: CGPoint {
        return CGPoint(x: minX, y: maxY)
    }
    
    var leftMiddle: CGPoint {
        return CGPoint(x: minX, y: midY)
    }
    
    var topMiddle: CGPoint {
        return CGPoint(x: midX, y: minY)
    }
    
    var rightMiddle: CGPoint {
        return CGPoint(x: maxX, y: midY)
    }
    
    var bottomMiddle: CGPoint {
        return CGPoint(x: midX, y: maxY)
    }

    var cg_width: CGFloat {
        get {
            return self.width
        }
        set(width) {
            size.width = width
        }
    }
    
    var cg_halfWidth: CGFloat {
        get {
            return cg_width / 2.0
        }
        set {
            cg_width = newValue * 2
        }
    }
    
    var cg_height: CGFloat {
        get {
            return self.height
        }
        set(height) {
            size.height = height
        }
    }
    
    var cg_halfHeight: CGFloat {
        get {
            return cg_height / 2.0
        }
        set {
            cg_height = newValue * 2
        }
    }
    
    var center: CGPoint {
        get {
            return CGPoint(x: cg_midX, y: cg_midY)
        }
        set {
            cg_midX = newValue.x
            cg_midY = newValue.y
        }
    }
    
    var cg_midX: CGFloat {
        get {
            return self.midX
        }
        set {
            origin.x = newValue - cg_halfWidth
        }
    }
    
    var cg_midY: CGFloat {
        get {
            return self.midY
        }
        set {
            origin.y = newValue - cg_halfHeight
        }
    }
    
}



