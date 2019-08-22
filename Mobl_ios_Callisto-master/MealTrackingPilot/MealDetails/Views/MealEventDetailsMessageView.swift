//
//  MealEventDetailsMessageView.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 5/18/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

class MealEventDetailsMessageView: UIView {

    private struct Constants {
        static let labelFontSize: Float = UIDevice.current.isSmallWidth ? 13 : 14
    }

    @IBOutlet weak var bubbleShadowView: UIView!
    @IBOutlet weak var bubbleView: RoundedCornerView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!

    let borderLayer = CAShapeLayer()

    override func awakeFromNib() {
        super.awakeFromNib()
        setupLabel()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupBubbleView()
    }

    private func setupLabel() {
        label.font = UIFont.openSansBoldFont(size: Constants.labelFontSize)
    }

    private func setupBubbleView() {
        bubbleView.roundedCorners = [.topLeft, .topRight, .bottomRight]

        if let maskLayer = bubbleView.layer.mask as? CAShapeLayer {
            borderLayer.frame = maskLayer.frame
            borderLayer.path = maskLayer.path
            borderLayer.strokeColor = UIColor.piPaleGreyTwo.cgColor
            borderLayer.lineWidth = 4.0
            borderLayer.fillColor = UIColor.clear.cgColor
            if borderLayer.superlayer == nil {
                bubbleView.layer.addSublayer(borderLayer)
            }
        }

        let shadowLayer = bubbleShadowView.layer
        shadowLayer.shadowColor = UIColor.piDenim.cgColor
        shadowLayer.shadowOpacity = 0.06
        shadowLayer.shadowRadius = 6.0
        shadowLayer.shadowOffset = CGSize(width: 0, height: 2)
    }

    func configure(withImage image: UIImage, text: String, animated: Bool = false) {
        let updateContent = {
            self.imageView.image = image
            self.label.text = text
        }
        if animated {
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    self.imageView.alpha = 0
                    self.label.alpha = 0
                },
                completion: { _ in
                    updateContent()
                    UIView.animate(withDuration: 0.3) {
                        self.imageView.alpha = 1
                        self.label.alpha = 1
                    }
                })
        } else {
            updateContent()
        }
    }
}
