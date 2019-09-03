//
//  DashboardHomeButton.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/20/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

public final class DashboardHomeButton: UIControl {

    // MARK: - Properties

    private lazy var backgroundView: GradientView = {
        let view = GradientView(colors: [], direction: .vertical)
        view.isUserInteractionEnabled = false
        view.layer.masksToBounds = true
        return view
    }()

    var chevronAlpha: CGFloat = 0 {
        didSet {
            chevronImageView.alpha = chevronAlpha
        }
    }
    private lazy var chevronImageView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "iconDownArrow"))
        imageView.alpha = self.chevronAlpha
        imageView.isUserInteractionEnabled = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    var gradientDirection = GradientView.Direction.vertical {
        didSet {
            backgroundView.direction = gradientDirection
        }
    }

    var normalBackgroundColors = [UIColor]() {
        didSet {
            refreshColors()
        }
    }

    var highlightedBackgroundColors = [UIColor]() {
        didSet {
            refreshColors()
        }
    }

    public override var isHighlighted: Bool {
        didSet {
            refreshColors()
        }
    }

    private func refreshColors() {
        var currentColors: [UIColor]
        if isHighlighted {
            currentColors = highlightedBackgroundColors
        } else {
            currentColors = normalBackgroundColors
        }
        backgroundView.colors = currentColors
    }

    // MARK: - Lifecycle

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    public override init(frame: CGRect) {
        fatalError()
    }

    init() {
        super.init(frame: .zero)
        setup()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
        backgroundView.layer.cornerRadius = bounds.width / 2
    }

    // MARK: Setup

    private func setup() {
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 3
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 2
        layer.shadowOpacity = 0.3
        setupBackground()
        setupChevron()
    }

    private func setupBackground() {
        addSubview(backgroundView)

        constrainView(toAllEdges: backgroundView)
    }

    private func setupChevron() {
        addSubview(chevronImageView)

        chevronImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        chevronImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

}
