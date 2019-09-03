//
//  IconMessageContentView.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/21/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

class IconMessageContentView: UIView {

    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!

    var messageViewModel: ChatMessageViewModelProtocol? {
        didSet {
            configureFromViewModel()
        }
    }

    private func configureFromViewModel() {
        guard let messageViewModel = messageViewModel else {
            return
        }

        textLabel.attributedText = messageViewModel.attributedText
        iconImageView.image = messageViewModel.iconImage
    }
}
