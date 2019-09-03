//
//  TextEntry+Extensions.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 4/5/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

fileprivate struct Constants {
    static let returnButtonContainerViewHeight: CGFloat = UIDevice.current.isSmallHeight ? 52.0 : 68.0
    static let returnButtonInset: CGFloat = UIDevice.current.isSmallHeight ? 6.0 : 14.0
    static let disclaimerViewHeight: CGFloat = UIDevice.current.isSmallHeight ? 44.0 : 80.0
    static let disclaimerLabelInset: CGFloat = 16.0
    static let disclaimerFontSize: Float = UIDevice.current.isSmallHeight ? 12.0 : 14.0
}

fileprivate func customReturnButtonInputAccessoryView(withImage image: UIImage, disclaimerText: String? = nil, target: Any?, action: Selector) -> UIView {
    let inputAccessoryView = UIView(frame: CGRect.zero)
    inputAccessoryView.translatesAutoresizingMaskIntoConstraints = false
    inputAccessoryView.backgroundColor = UIColor.clear


    let nextButton = UIButton()
    nextButton.setImage(image, for: .normal)
    nextButton.addTarget(target, action: action, for: .touchUpInside)

    let buttonContainerView = customReturnButtonContainerView(withImage: image, target: target, action: action)
    inputAccessoryView.addSubview(buttonContainerView)

    let height: CGFloat

    if let disclaimerText = disclaimerText {
        let disclaimerView = disclaimerContainerView(text: disclaimerText)

        inputAccessoryView.addSubview(disclaimerView)
        inputAccessoryView.constrainView(toTop: buttonContainerView)
        inputAccessoryView.constrainView(toLeft: buttonContainerView)
        inputAccessoryView.constrainView(toRight: buttonContainerView)
        inputAccessoryView.constrainView(toBottom: disclaimerView)

        inputAccessoryView.constrainView(toLeft: disclaimerView)
        inputAccessoryView.constrainView(toRight: disclaimerView)
        inputAccessoryView.constrainView(disclaimerView, below: buttonContainerView)

        height = Constants.returnButtonContainerViewHeight + Constants.disclaimerViewHeight
    } else {
        inputAccessoryView.constrainView(toAllEdges: buttonContainerView)

        height = Constants.returnButtonContainerViewHeight
    }

    inputAccessoryView.frame = CGRect(x: 0, y: 0, width: 0, height: height)

    return inputAccessoryView
}

fileprivate func customReturnButtonContainerView(withImage image: UIImage, target: Any?, action: Selector) -> UIView {
    let button = UIButton()
    button.setImage(image, for: .normal)
    button.addTarget(target, action: action, for: .touchUpInside)

    let containerView = UIView()
    containerView.backgroundColor = UIColor.clear
    
    containerView.addSubview(button)
    containerView.constrainView(containerView, toHeight: Constants.returnButtonContainerViewHeight)

    containerView.constrainView(button, attribute: .centerY, to: containerView, attribute: .centerY)
    containerView.constrainView(toRight: button, withInset: -Constants.returnButtonInset)

    return containerView
}

fileprivate func disclaimerContainerView(text: String) -> UIView {
    let containerView = UIView()
    containerView.backgroundColor = UIColor.piDenim.withAlphaComponent(0.1)

    let disclaimerLabel = UILabel()
    disclaimerLabel.backgroundColor = UIColor.clear
    disclaimerLabel.text = text
    disclaimerLabel.textColor = UIColor.piDenim.withAlphaComponent(0.5)
    disclaimerLabel.font = UIFont.openSansItalicFont(size: Constants.disclaimerFontSize)
    disclaimerLabel.numberOfLines = 0

    containerView.addSubview(disclaimerLabel)
    containerView.constrainView(disclaimerLabel, attribute: .centerY, to: containerView, attribute: .centerY)
    containerView.constrainView(disclaimerLabel, to: UIEdgeInsets(top: 0, left: Constants.disclaimerLabelInset, bottom: 0, right: Constants.disclaimerLabelInset))
    containerView.constrainView(containerView, toHeight: Constants.disclaimerViewHeight)

    return containerView
}

public extension UITextField {
    func configureCustomReturnButton(withImage image: UIImage = #imageLiteral(resourceName: "checkWithWhiteBackground"), disclaimerText: String? = nil) {
        inputAccessoryView = customReturnButtonInputAccessoryView(withImage: image, disclaimerText: disclaimerText, target: self, action: #selector(customReturnButtonTapped))
    }

    @objc private func customReturnButtonTapped() {
        sendActions(for: .editingDidEndOnExit)
    }
}

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
