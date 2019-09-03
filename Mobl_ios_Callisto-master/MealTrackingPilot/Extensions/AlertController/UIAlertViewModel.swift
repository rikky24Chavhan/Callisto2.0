//
//  PilotUIAlertViewModel.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 5/3/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

public final class UIAlertViewModel {
    private(set) var title: String?
    private(set) var message: String?
    private(set) var preferredStyle: UIAlertController.Style
    private(set) var actionViewModels: [UIAlertActionViewModel]

    init(title: String?, message: String?, preferredStyle: UIAlertController.Style, actionViewModels: [UIAlertActionViewModel]) {
        self.title = title
        self.message = message
        self.preferredStyle = preferredStyle
        self.actionViewModels = actionViewModels
    }
}

extension UIAlertController {
    public convenience init(viewModel: UIAlertViewModel) {
        self.init(title: viewModel.title, message: viewModel.message, preferredStyle: viewModel.preferredStyle)

        for actionViewModel in viewModel.actionViewModels {
            addAction(UIAlertAction(viewModel: actionViewModel))
        }
    }
}
