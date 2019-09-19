//
//  CopyrightTableViewCell.swift
//  MealTrackingPilot
//
//  Created by Steve Galbraith on 8/7/18.
//  Copyright © 2018 Intrepid. All rights reserved.
//

import UIKit

class CopyrightTableViewCell: UITableViewCell {

    @IBOutlet var logoImageView: UIImageView!
    @IBOutlet var imageViewToTopConstraint: NSLayoutConstraint!
    @IBOutlet var copyrightLabelToBottomConstraint: NSLayoutConstraint!
    
    fileprivate struct Constants {
        static let minimumDistanceToImageView: CGFloat = 20
        static let defaultDistanceToBottom: CGFloat = 10
    }

    func configure(with topView: UIView, distanceFromBottom: CGFloat = Constants.defaultDistanceToBottom) {
        contentView.addSubview(topView)

        // Background Color
        contentView.backgroundColor = topView.backgroundColor

        // Constraints
        if distanceFromBottom != Constants.defaultDistanceToBottom {
            imageViewToTopConstraint.priority = .defaultHigh
        }
        copyrightLabelToBottomConstraint.constant = distanceFromBottom

        topView.heightAnchor.constraint(equalToConstant: topView.frame.height).isActive = true
        _ = contentView.constrainView(toTop: topView)
        _ = contentView.constrainView(toLeft: topView)
        _ = contentView.constrainView(toRight: topView)
        _ = contentView.constrainView(logoImageView, attribute: .top, to: topView, attribute: .bottom, constant: Constants.minimumDistanceToImageView, multiplier: 1.0, relation: .greaterThanOrEqual)
    }
}
