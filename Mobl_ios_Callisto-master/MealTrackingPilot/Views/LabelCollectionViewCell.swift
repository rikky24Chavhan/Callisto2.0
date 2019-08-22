//
//  LabelCollectionViewCell.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/29/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import Intrepid

class LabelCollectionViewCell: UICollectionViewCell {

    let label = UILabel()

    override var isHighlighted: Bool {
        didSet {
            label.alpha = isHighlighted ? 0.3 : 1.0
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabel()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLabel()
    }

    private func setupLabel() {
        contentView.addSubview(label)
        contentView.constrainView(toAllEdges: label)

        contentView.backgroundColor = UIColor.clear
        label.backgroundColor = UIColor.clear
    }
}
