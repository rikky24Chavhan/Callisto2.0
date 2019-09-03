//
//  RoundedCornerView.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/17/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

public final class RoundedCornerView: UIView {

    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            updateMask()
        }
    }

    var roundedCorners: UIRectCorner = [] {
        didSet {
            updateMask()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        updateMask()
    }

    private func updateMask() {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: roundedCorners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        let cornerMask = CAShapeLayer()
        cornerMask.frame = self.bounds
        cornerMask.path = path.cgPath
        layer.mask = cornerMask
    }
}
