//
//  UnderlinedTextField.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/20/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

class UnderlinedTextField: UITextField {

    var lineColor: UIColor = UIColor.white {
        didSet {
            setNeedsDisplay()
        }
    }

    var lineWidth: CGFloat = 1 {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setup() {
        borderStyle = UITextBorderStyle.none
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: NSNotification.Name.UITextFieldTextDidChange,
            object: self)
    }

    @objc private func textDidChange(notification: NSNotification) {
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard
            (text ?? "").ip_length == 0,
            let context = UIGraphicsGetCurrentContext()
        else { return }

        context.setStrokeColor(lineColor.cgColor)
        context.setLineWidth(lineWidth)

        context.beginPath()
        context.move(to: CGPoint(x: bounds.minX, y: bounds.height - lineWidth))
        context.addLine(to: CGPoint(x: bounds.maxX, y: bounds.height - lineWidth))
        context.closePath()
        context.strokePath()
    }
}
