//
//  CircleProgressView.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/27/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

public final class CircleProgressView: UIView {

    // MARK: - Properties

    private struct Constants {
        static let angleOffsetForZero: CGFloat = -.pi / 2

        static let outerRingViewTag = 1
        static let innerCircleViewTag = 2
        static let countLabelTag = 3
    }

    var outerRingColor: UIColor? = nil {
        didSet {
            outerRingView.backgroundColor = outerRingColor
        }
    }

    var outerRingProgressColor: UIColor? = nil {
        didSet {
            filledArcLayer.strokeColor = outerRingProgressColor?.cgColor
        }
    }

    var outerRingWidth: CGFloat = 3 {
        didSet {
            innerCircleLeadingConstraint.constant = outerRingWidth
            innerCircleTrailingConstraint.constant = -outerRingWidth
            innerCircleTopConstraint.constant = outerRingWidth
            innerCircleBottomConstraint.constant = -outerRingWidth
        }
    }

    var innerCircleColor: UIColor? = nil {
        didSet {
            innerCircleView.backgroundColor = innerCircleColor
        }
    }

    var currentCount: Int = 0 {
        didSet {
            countLabel.text = "\(currentCount)"
        }
    }

    var maxCount: Int? = nil {
        didSet {
            layoutFilledPath()
        }
    }

    private lazy var outerRingView: UIView = {
        let ringView = UIView()
        ringView.tag = Constants.outerRingViewTag
        ringView.layer.masksToBounds = true
        ringView.backgroundColor = self.outerRingColor
        ringView.translatesAutoresizingMaskIntoConstraints = false
        return ringView
    }()

    private lazy var innerCircleView: UIView = {
        let circleView = UIView()
        circleView.tag = Constants.innerCircleViewTag
        circleView.layer.masksToBounds = true
        circleView.backgroundColor = self.innerCircleColor
        circleView.translatesAutoresizingMaskIntoConstraints = false
        return circleView
    }()

    private var innerCircleLeadingConstraint: NSLayoutConstraint!
    private var innerCircleTrailingConstraint: NSLayoutConstraint!
    private var innerCircleTopConstraint: NSLayoutConstraint!
    private var innerCircleBottomConstraint: NSLayoutConstraint!

    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.openSansBoldFont(size: 16)
        label.text = "\(self.currentCount)"
        label.tag = Constants.countLabelTag
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var filledArcLayer = CAShapeLayer()

    private var value: CGFloat {
        guard let maxCount = maxCount, maxCount > 0 else { return 0 }
        return CGFloat(currentCount) / CGFloat(maxCount)
    }

    private var radius: CGFloat {
        return (min(bounds.width, bounds.height) - outerRingWidth) / 2
    }

    // MARK: - Lifecycle

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public convenience init() {
        self.init(frame: .zero)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        configureCornerRadius()
        layoutFilledPath()
    }

    // MARK: - Actions

    private func getAngle(value: CGFloat) -> CGFloat {
        return value * 2 * .pi + Constants.angleOffsetForZero
    }

    private func configureCornerRadius() {
        outerRingView.layer.cornerRadius = bounds.width / 2
        innerCircleView.layer.cornerRadius = (bounds.width - outerRingWidth * 2) / 2
    }

    // MARK: Setup

    private func setup() {
        if subviews.count == 0 {
            addSubview(outerRingView)
            addSubview(innerCircleView)
        } else {
            if let outerRingView = viewWithTag(Constants.outerRingViewTag),
                let innerRingView = viewWithTag(Constants.innerCircleViewTag) {
                self.outerRingView = outerRingView
                self.innerCircleView = innerRingView
            } else {
                subviews.forEach { $0.removeFromSuperview() }

                addSubview(outerRingView)
                addSubview(innerCircleView)
            }
        }

        filledArcLayer.fillColor = UIColor.clear.cgColor
        filledArcLayer.strokeColor = outerRingProgressColor?.cgColor
        filledArcLayer.lineWidth = outerRingWidth
        filledArcLayer.lineCap = CAShapeLayerLineCap.round
        layer.addSublayer(filledArcLayer)

        setupInnerCircleView()

        configureCornerRadius()

        // Constraints
        constrainView(toAllEdges: outerRingView)

        innerCircleLeadingConstraint = innerCircleView.leadingAnchor.constraint(equalTo: outerRingView.leadingAnchor, constant: outerRingWidth)
        innerCircleLeadingConstraint.isActive = true

        innerCircleTrailingConstraint = innerCircleView.trailingAnchor.constraint(equalTo: outerRingView.trailingAnchor, constant: -outerRingWidth)
        innerCircleTrailingConstraint.isActive = true

        innerCircleTopConstraint = innerCircleView.topAnchor.constraint(equalTo: outerRingView.topAnchor, constant: outerRingWidth)
        innerCircleTopConstraint.isActive = true

        innerCircleBottomConstraint = innerCircleView.bottomAnchor.constraint(equalTo: outerRingView.bottomAnchor, constant: -outerRingWidth)
        innerCircleBottomConstraint.isActive = true
    }

    private func setupInnerCircleView() {
        if innerCircleView.subviews.count == 0 {
            innerCircleView.addSubview(countLabel)
        } else {
            if let countLabel = innerCircleView.viewWithTag(Constants.countLabelTag) as? UILabel {
                self.countLabel = countLabel
            } else {
                innerCircleView.subviews.forEach { $0.removeFromSuperview() }

                innerCircleView.addSubview(countLabel)
            }
        }

        countLabel.leadingAnchor.constraint(equalTo: innerCircleView.leadingAnchor).isActive = true
        countLabel.trailingAnchor.constraint(equalTo: innerCircleView.trailingAnchor).isActive = true
        countLabel.centerYAnchor.constraint(equalTo: innerCircleView.centerYAnchor).isActive = true
    }

    private func layoutFilledPath() {
        let filledArcPath = UIBezierPath(
            arcCenter: CGPoint(x: bounds.width / 2, y: bounds.height / 2),
            radius: radius,
            startAngle: Constants.angleOffsetForZero,
            endAngle: getAngle(value: value),
            clockwise: true)

        filledArcLayer.path = filledArcPath.cgPath
    }
}
