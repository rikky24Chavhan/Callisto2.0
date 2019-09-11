//
//  UIView+Extensions.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/24/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

extension UIView {
    
    func copyView() -> UIView? {
        return NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self)) as? UIView
    }
    class func fromNib(_ nibNameOrNil: String? = nil) -> Self {
        return fromNib(nibNameOrNil, type: self)
    }
    
    class func fromNib<T: UIView>(_ nibNameOrNil: String? = nil, type: T.Type) -> T {
        let view: T? = fromNib(nibNameOrNil, type: T.self)
        return view!
    }
    
    class func fromNib<T: UIView>(_ nibNameOrNil: String? = nil, type: T.Type) -> T? {
        var view: T?
        let name: String
        if let nibName = nibNameOrNil {
            name = nibName
        } else {
            name = nibName
        }
        let nibViews = Bundle.main.loadNibNamed(name, owner: nil, options: nil)
        for thisView in nibViews ?? [] {
            if let tog = thisView as? T {
                view = tog
            }
        }
        return view
    }
    
    class var nibName: String {
        let name = "\(self)".components(separatedBy: ".").first ?? ""
        return name
    }
    class var nib: UINib? {
        if Bundle.main.path(forResource: nibName, ofType: "nib") != nil {
            return UINib(nibName: nibName, bundle: nil)
        } else {
            return nil
        }
    }
    
    struct Constants {
        static let returnButtonContainerViewHeight: CGFloat = UIDevice.current.isSmallHeight ? 52.0 : 68.0
        static let returnButtonInset: CGFloat = UIDevice.current.isSmallHeight ? 6.0 : 14.0
        static let disclaimerViewHeight: CGFloat = UIDevice.current.isSmallHeight ? 44.0 : 80.0
        static let disclaimerLabelInset: CGFloat = 16.0
        static let disclaimerFontSize: Float = UIDevice.current.isSmallHeight ? 12.0 : 14.0
    }
    
     func customReturnButtonInputAccessoryView(withImage image: UIImage, disclaimerText: String? = nil, target: Any?, action: Selector) -> UIView {
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
            _ = inputAccessoryView.constrainView(toTop: buttonContainerView)
            _ = inputAccessoryView.constrainView(toLeft: buttonContainerView)
            _ = inputAccessoryView.constrainView(toRight: buttonContainerView)
            _ = inputAccessoryView.constrainView(toBottom: disclaimerView)
            
            _ = inputAccessoryView.constrainView(toLeft: disclaimerView)
            _ = inputAccessoryView.constrainView(toRight: disclaimerView)
            _ = inputAccessoryView.constrainView(disclaimerView, below: buttonContainerView)
            
            height = Constants.returnButtonContainerViewHeight + Constants.disclaimerViewHeight
        } else {
            _ = inputAccessoryView.constrainView(toAllEdges: buttonContainerView)
            
            height = Constants.returnButtonContainerViewHeight
        }
        
        inputAccessoryView.frame = CGRect(x: 0, y: 0, width: 0, height: height)
        
        return inputAccessoryView
    }
    
     func customReturnButtonContainerView(withImage image: UIImage, target: Any?, action: Selector) -> UIView {
        let button = UIButton()
        button.setImage(image, for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor.clear
        
        containerView.addSubview(button)
        _ = containerView.constrainView(containerView, toHeight: Constants.returnButtonContainerViewHeight)
        
        _ = containerView.constrainView(button, attribute: .centerY, to: containerView, attribute: .centerY)
        _ = containerView.constrainView(toRight: button, withInset: -Constants.returnButtonInset)
        
        return containerView
    }
    
     func disclaimerContainerView(text: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.piDenim.withAlphaComponent(0.1)
        
        let disclaimerLabel = UILabel()
        disclaimerLabel.backgroundColor = UIColor.clear
        disclaimerLabel.text = text
        disclaimerLabel.textColor = UIColor.piDenim.withAlphaComponent(0.5)
        disclaimerLabel.font = UIFont.openSansItalicFont(size: Constants.disclaimerFontSize)
        disclaimerLabel.numberOfLines = 0
        
        containerView.addSubview(disclaimerLabel)
        _ = containerView.constrainView(disclaimerLabel, attribute: .centerY, to: containerView, attribute: .centerY)
        _ = containerView.constrainView(disclaimerLabel, to: UIEdgeInsets(top: 0, left: Constants.disclaimerLabelInset, bottom: 0, right: Constants.disclaimerLabelInset))
        _ = containerView.constrainView(containerView, toHeight: Constants.disclaimerViewHeight)
        
        return containerView
    }
    
}

