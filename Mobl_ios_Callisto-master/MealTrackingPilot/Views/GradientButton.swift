//
//  GradientButton.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 5/2/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

final class GradientButton: UIButton {

    // MARK: - Properties

    var gradientDirection: GradientView.Direction = .horizontal {
        didSet {
            containerView.direction = gradientDirection
        }
    }

    var gradientColors: [UIColor] = [] {
        didSet {
            containerView.colors = gradientColors
        }
    }

    var cornerRadius: CGFloat = 8.0 {
        didSet {
            containerView.layer.cornerRadius = cornerRadius
        }
    }

    var title: String? = nil {
        didSet {
            textLabel.text = title
        }
    }

    private lazy var containerView: GradientView = {
        let view = GradientView(colors: [], direction: .horizontal)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .piBlack16
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.openSansBoldFont(size: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override var isHighlighted: Bool {
        didSet {
            overlayView.isHidden = !isHighlighted
        }
    }

    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.3
        }
    }

    // MARK: - Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    // MARK: Setup

    func setup() {
        setupShadow()
        setupContainerView()

        addSubview(containerView)
        _ = constrainView(toAllEdges: containerView)

        containerView.backgroundColor = UIColor.white
    }

    func setupShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
    }

    func setupContainerView() {
        containerView.isUserInteractionEnabled = false

        containerView.layer.masksToBounds = true
        containerView.layer.cornerRadius = 8

        containerView.addSubview(textLabel)
        _ = containerView.constrainView(toAllEdges: textLabel)

        containerView.addSubview(overlayView)
        _ = containerView.constrainView(toAllEdges: overlayView)
    }
}
