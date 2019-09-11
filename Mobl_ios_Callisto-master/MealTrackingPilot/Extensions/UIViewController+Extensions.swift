//
//  UIViewController+Extensions.swift
//  MealTrackingPilot
//
//  Created by sugapriya on 09/09/19.
//  Copyright © 2019 Intrepid. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    public static var nibName: String {
        return "\(self)".components(separatedBy: ".").last!
    }
    
    public func addChildViewController(_ controller: UIViewController?) {
        addChildViewController(controller, to: view)
    }
    
    public func addChildViewController(_ controller: UIViewController?, to view: UIView?) {
        if let controller = controller {
            addChild(controller)
        }
        if let view = controller?.view {
            view.addSubview(view)
        }
        controller?.didMove(toParent: self)
    }
    
    public func removeFromParentViewController() {
        willMove(toParent: nil)
        removeFromParent()
        view.removeFromSuperview()
        didMove(toParent: nil)
    }
}
