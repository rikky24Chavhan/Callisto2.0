//
//  TextEntry+Extensions.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 4/5/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

public extension UITextView {
    func configureCustomReturnButton(withImage image: UIImage = #imageLiteral(resourceName: "checkWithWhiteBackground"), disclaimerText: String? = nil) {
        inputAccessoryView = customReturnButtonInputAccessoryView(withImage: image, disclaimerText: disclaimerText, target: self, action: #selector(customReturnButtonTapped))
    }

    var customReturnButtonAccessoryViewHeight: CGFloat {
        return Constants.returnButtonContainerViewHeight
    }

    @objc private func customReturnButtonTapped() {
        delegate?.textViewDidEndEditing?(self)
    }
}
