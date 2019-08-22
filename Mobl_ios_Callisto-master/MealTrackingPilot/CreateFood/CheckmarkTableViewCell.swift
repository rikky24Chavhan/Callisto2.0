//
//  CheckmarkTableViewCell.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/21/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

protocol CheckmarkTableViewCellViewModel {
    var text: String { get }
    var isSelected: Bool { get }
}

class CheckmarkTableViewCell: UITableViewCell {

    @IBOutlet weak var checkmarkButton: UIButton!
    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear

        checkmarkButton.isUserInteractionEnabled = false    // Cell selection mechanism is used instead
        checkmarkButton.setImage(#imageLiteral(resourceName: "checkLightUnselected"), for: .normal)
        checkmarkButton.setImage(#imageLiteral(resourceName: "checkLightSelected"), for: .selected)
        checkmarkButton.setImage(#imageLiteral(resourceName: "checkLightSelected"), for: [.selected, .highlighted])
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        label.font = selected ? UIFont.openSansSemiboldFont(size: 28.0) : UIFont.openSansFont(size: 28.0)
        checkmarkButton.isSelected = selected
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        checkmarkButton.isHighlighted = highlighted
    }

    func configure(viewModel: CheckmarkTableViewCellViewModel) {
        label.text = viewModel.text
        isSelected = viewModel.isSelected
    }
}
