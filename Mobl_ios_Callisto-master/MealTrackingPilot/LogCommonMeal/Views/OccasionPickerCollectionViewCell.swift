//
//  OccasionPickerCollectionViewCell.swift
//  MealTrackingPilot
//
//  Created by Gowtham on 23/09/19.
//  Copyright © 2019 LTTS. All rights reserved.
//

import Foundation
import UIKit

class OccasionPickerCollectionViewCell: UICollectionViewCell {
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
                newCustomView.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(newCustomView)
                
                contentView.leadingAnchor.constraint(equalTo: newCustomView.leadingAnchor).isActive = true
                contentView.trailingAnchor.constraint(equalTo: newCustomView.trailingAnchor).isActive = true
                contentView.topAnchor.constraint(equalTo: newCustomView.topAnchor).isActive = true
                contentView.bottomAnchor.constraint(equalTo: newCustomView.bottomAnchor).isActive = true
            }
        }
    }
}
