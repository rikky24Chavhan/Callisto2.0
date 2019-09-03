//
//  MealOccasionPickerItemViewModel.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/21/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

class MealOccasionPickerItemViewModel {
    let occasion: MealOccasion?
    var highlighted: Bool

    init(occasion: MealOccasion?, highlighted: Bool = false) {
        self.occasion = occasion
        self.highlighted = highlighted
    }

    var itemTransform: CGAffineTransform {
        return highlighted ? .identity : CGAffineTransform(scaleX: 0.89, y: 0.89)
    }

    var alpha: CGFloat {
        return highlighted ? 1.0 : 0.5
    }

    var title: String {
        return occasion?.displayValue ?? "All"
    }

    var titleFont: UIFont {
        return highlighted ? UIFont.openSansSemiboldFont(size: 17) : UIFont.openSansFont(size: 14)
    }

    var icon: UIImage? {
        if let occasion = occasion {
            return occasion.icon
        }
        return #imageLiteral(resourceName: "allIllustration")
    }
}

fileprivate extension MealOccasion {
    var icon: UIImage? {
        switch self {
        case .breakfast:
            return #imageLiteral(resourceName: "breakfastIllustration")
        case .lunch:
            return #imageLiteral(resourceName: "lunchIllustration")
        case .dinner:
            return #imageLiteral(resourceName: "dinnerIllustration")
        case .snack:
            return #imageLiteral(resourceName: "snackIllustration")
        case .dessert:
            return #imageLiteral(resourceName: "dessertIllustration")
        case .drink:
            return #imageLiteral(resourceName: "drinksIllustration")
        }
    }
}
