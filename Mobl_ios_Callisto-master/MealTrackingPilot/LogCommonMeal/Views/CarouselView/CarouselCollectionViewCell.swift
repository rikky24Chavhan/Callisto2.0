//
//  CarouselCollectionViewCell.swift
//  CarouselView
//
//  Created by Rikky Chavhan on 20/08/19.
//  Copyright © 2019 L&T. All rights reserved.
//

import UIKit

class CarouselCollectionViewCell: UICollectionViewCell {
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: self.contentView.frame.width, height: self.contentView.frame.height))
        titleLabel.textAlignment = .center
        return titleLabel
    }()
    
    var customView: UIView? {
        willSet {
            if customView != newValue {
                customView?.removeFromSuperview()
            }
        }
        didSet {
            if let newCustomView = customView {
                contentView.addSubview(newCustomView)
                newCustomView.translatesAutoresizingMaskIntoConstraints = false
                for format in [ "H:|[customView]|", "V:|[customView]|" ] {
                    contentView.addConstraints(NSLayoutConstraint.constraints(
                        withVisualFormat: format,
                        options: [],
                        metrics: nil,
                        views: ["customView" : newCustomView]
                    ))
                }
            }
        }
    }
}
