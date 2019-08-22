//
//  UIAlertActionViewModel.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 5/3/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

public final class UIAlertActionViewModel {
    private(set) var title: String?
    private(set) var style: UIAlertActionStyle = .default
    private(set) var handler: ((UIAlertAction) -> Void)?

    public init(title: String?, style: UIAlertActionStyle, handler: ((UIAlertAction) -> Swift.Void)? = nil) {
        self.title = title
        self.style = style
        self.handler = handler
    }

    public class func cancelAction() -> UIAlertActionViewModel {
        return UIAlertActionViewModel(title: "Cancel", style: .cancel)
    }
}

extension UIAlertAction {
    public convenience init(viewModel: UIAlertActionViewModel) {
        self.init(title: viewModel.title, style: viewModel.style, handler: viewModel.handler)
    }
}
