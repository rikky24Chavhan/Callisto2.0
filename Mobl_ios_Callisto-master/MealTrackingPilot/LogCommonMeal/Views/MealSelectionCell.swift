//
//  MealSelectionCell.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/18/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MealSelectionCell: UITableViewCell {

    static let minimumHeight: CGFloat = 72.0

    @IBOutlet weak var selectionIconImageView: UIImageView!
    @IBOutlet weak var doseIconImageView: UIImageView!

    @IBOutlet weak var mealNameLabel: UILabel!
    @IBOutlet weak var mealLocationAndPortionLabel: UILabel!
    @IBOutlet weak var dosageRecommendationLabel: UILabel!
    @IBOutlet weak var circleProgressView: CircleProgressView!
    @IBOutlet weak var separatorView: UIView!

    private let bag = DisposeBag()

    var viewModel: MealSelectionCellViewModel? {
        didSet {
            configureFromViewModel()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        separatorView.backgroundColor = UIColor.piGreyblue.withAlphaComponent(0.1)

        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: MealSelectionCell.minimumHeight).isActive = true
    }

    // MARK: ViewModel Binding

    func configureFromViewModel() {
        guard let viewModel = viewModel else {
            return
        }

        mealNameLabel.text = viewModel.mealName
        mealNameLabel.font = viewModel.mealNameFont
        mealLocationAndPortionLabel.text = viewModel.mealLocationAndPortion
        dosageRecommendationLabel.text = viewModel.dosageRecommendationText
        selectionIconImageView.image = UIImage(named: viewModel.selectionIconImageName)
        doseIconImageView.isHidden = viewModel.doseIconHidden

        circleProgressView.configure(forMealClassification: viewModel.mealClassification, hasDosageRecommendation: viewModel.hasDosageRecommendation)
        circleProgressView.currentCount = viewModel.numberOfTimesMealLogged
        circleProgressView.maxCount = viewModel.mealLogGoal
    }
}

extension CircleProgressView {
    func configure(forMealClassification mealClassification: MealClassification, hasDosageRecommendation: Bool) {
        switch mealClassification {
        case .common:
            innerCircleColor = UIColor.piTopaz
            outerRingWidth = 3.0
            outerRingColor = hasDosageRecommendation ? UIColor.piDenim : UIColor.piTopaz40
        case .test:
            innerCircleColor = UIColor.piLightOrange
            outerRingWidth = 4.0
            outerRingColor = UIColor.piLightOrange40
            outerRingProgressColor = UIColor.piDenim
        }
    }
}
