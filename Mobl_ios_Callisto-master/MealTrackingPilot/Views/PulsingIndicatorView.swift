//
//  PulsingIndicatorView.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/28/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class PulsingIndicatorView: UIView {

    private struct Constants {
        static let ringViewAlpha: CGFloat = 0.4
        static let ringViewInsets = UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)

        static let pulseDuration: TimeInterval = 4.0
        static let pulseTransformInitial = CGAffineTransform(scaleX: 0.01, y: 0.01)
        static let pulseTransformFinal = CGAffineTransform(scaleX: 1.5, y: 1.5)
    }

    let centerView = UIView()
    let ringView = UIView()
    var tempRingView: UIView?

    var color: UIColor? {
        get {
            return centerView.backgroundColor
        }
        set {
            centerView.backgroundColor = newValue
            ringView.backgroundColor = newValue?.withAlphaComponent(Constants.ringViewAlpha)
            tempRingView?.backgroundColor = ringView.backgroundColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        backgroundColor = UIColor.clear
        color = UIColor.black

        clipsToBounds = false

        addSubview(ringView)
        _ = constrainView(ringView, to: Constants.ringViewInsets)

        addSubview(centerView)
        _ = constrainView(toAllEdges: centerView)

        centerView.layer.borderColor = UIColor.white.cgColor
        centerView.layer.borderWidth = 2.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        ringView.layer.cornerRadius = ringView.bounds.width / 2
        ringView.layer.masksToBounds = true

        centerView.layer.cornerRadius = centerView.bounds.width / 2
        centerView.layer.masksToBounds = true
    }

    func startPulsing() {
        ringView.transform = .identity
        ringView.alpha = 1

        let tempRingView = UIView(frame: ringView.frame)
        tempRingView.backgroundColor = ringView.backgroundColor
        tempRingView.layer.cornerRadius = tempRingView.bounds.width / 2
        tempRingView.layer.masksToBounds = true
        tempRingView.transform = Constants.pulseTransformInitial
        insertSubview(tempRingView, belowSubview: ringView)

        UIView.animate(withDuration: Constants.pulseDuration, delay: 0.0, options: [.repeat, .curveLinear], animations: {
            self.ringView.transform = Constants.pulseTransformFinal
            self.ringView.alpha = 0
            tempRingView.transform = .identity
        }, completion: nil)

        self.tempRingView = tempRingView
    }

    func stopPulsing() {
        ringView.layer.removeAllAnimations()

        tempRingView?.removeFromSuperview()
        tempRingView = nil
    }

    func resetPulsing() {
        stopPulsing()
        startPulsing()
    }
}

extension Reactive where Base: PulsingIndicatorView {
    var color: Binder<UIColor?> {
        return Binder<UIColor?>(self.base) { view, color in
            view.color = color
        }
    }
}
