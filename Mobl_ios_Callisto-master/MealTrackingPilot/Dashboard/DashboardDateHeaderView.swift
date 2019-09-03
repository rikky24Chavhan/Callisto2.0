//
//  DashboardDateHeaderView.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/14/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

final class DashboardDateHeaderView: UIView {

    // MARK: - Properties

    private struct Constants {
        static let topInset: CGFloat = 16.6
        static let bottomInset: CGFloat = 5.4
        static let horizontalInset: CGFloat = 16
    }

    var viewModel: DashboardHeaderViewModel? {
        didSet {
            weekdayLabel.attributedText = viewModel?.primaryText
            dateLabel.attributedText = viewModel?.secondaryText
        }
    }

    var isTopHeader: Bool = false {
        didSet {
            roundedBackgroundView.cornerRadius = isTopHeader ? 12 : 0
        }
    }

    var contentAlpha: CGFloat = 1 {
        didSet {
            weekdayLabel.alpha = contentAlpha
            dateLabel.alpha = contentAlpha
        }
    }

    private lazy var roundedBackgroundView: RoundedCornerView = {
        let view = RoundedCornerView()
        view.roundedCorners = [.topLeft, .topRight]
        view.backgroundColor = UIColor.piAlmostWhite
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var weekdayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false

        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    var dateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false

        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    // MARK: - Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    // MARK: - Actions

    // MARK: Setup

    private func setup() {
        backgroundColor = .clear
        addSubview(roundedBackgroundView)
        constrainView(toAllEdges: roundedBackgroundView)

        let stackView = UIStackView(arrangedSubviews: [weekdayLabel, dateLabel])
        stackView.axis = .horizontal
        stackView.alignment = .firstBaseline
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        // Constraints
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.horizontalInset).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.horizontalInset).isActive = true
        stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.topInset).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.bottomInset).isActive = true
    }
}
