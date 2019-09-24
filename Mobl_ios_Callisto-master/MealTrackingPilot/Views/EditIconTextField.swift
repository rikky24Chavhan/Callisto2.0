//
//  EditIconTextField.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/20/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

final class EditIconTextField: UnderlinedTextField {

    var iconImage: UIImage = #imageLiteral(resourceName: "editIconLight") {
        didSet {
            rightView = UIImageView(image: iconImage)
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

    private func setup() {
        rightViewMode = .unlessEditing
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.rightViewRect(forBounds: bounds)

        // Hide if text is empty
        guard
            let text = text,
            let font = font,
            text.count > 0
            else {
                // Position out-of-bounds but maintain size
                return rect.offsetBy(dx: 1000, dy: 0)
        }

        // Get current text size (calling `textRect(forBounds:)` will loop)
        let textWidth = (text as NSString).size(withAttributes: [NSAttributedString.Key.font : font]).width
        let preferredX = textWidth + 15.0
        rect.origin.x = min(rect.origin.x, preferredX)
        return rect
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        // Don't compensate for edit icon view
        return bounds.offsetBy(dx: 0, dy: 6.0)
    }
}
