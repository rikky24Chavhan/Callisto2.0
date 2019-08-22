//
//  RoundedModalPresentationController.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 5/25/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

class RoundedModalPresentationController: UIPresentationController {

    let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        return view
    }()

    var cornerRadius: CGFloat = 8.0
    var horizontalPadding: CGFloat = 8.0
    var maxVerticalPadding: CGFloat = 8.0

    override func presentationTransitionWillBegin() {
        guard
            let containerView = containerView,
            let presentedView = presentedView
        else {
            return
        }

        overlayView.frame = containerView.bounds
        overlayView.alpha = 0
        containerView.insertSubview(overlayView, belowSubview: presentedView)

        presentedView.layer.cornerRadius = cornerRadius
        presentedView.layer.shadowColor = UIColor.black.cgColor
        presentedView.layer.shadowOpacity = 0.5
        presentedView.layer.shadowRadius = 4.0
        presentedView.layer.shadowOffset = CGSize(width: 0, height: 2)

        presentedViewController.transitionCoordinator?.animate(
            alongsideTransition: { [weak self] context in
                self?.overlayView.alpha = 0.5
            },
            completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(
            alongsideTransition: { [weak self] context in
                self?.overlayView.alpha = 0
            },
            completion: nil)
    }

    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        return container.preferredContentSize
    }

    override var frameOfPresentedViewInContainerView : CGRect {
        guard
            let containerView = containerView,
            let presentedView = presentedView
        else {
            return CGRect.zero
        }

        presentedView.layoutIfNeeded()

        let maxFrame = containerView.bounds.insetBy(dx: horizontalPadding, dy: maxVerticalPadding)
        let preferredSize = presentedView.systemLayoutSizeFitting(maxFrame.size, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        return CGRect(origin: CGPoint(x: horizontalPadding, y: (containerView.frame.height - preferredSize.height) / 2), size: preferredSize)
    }

    override func viewWillTransition(to size: CGSize, with transitionCoordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: transitionCoordinator)

        guard let containerView = containerView else { return }

        transitionCoordinator.animate(
            alongsideTransition: { [weak self] context in
                self?.overlayView.frame = containerView.bounds
            },
            completion: nil)
    }
}
