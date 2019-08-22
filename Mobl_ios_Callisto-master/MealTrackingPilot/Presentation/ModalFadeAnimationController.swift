//
//  ModalFadeAnimationController.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 5/31/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

class ModalFadeAnimationController: NSObject, UIViewControllerAnimatedTransitioning {

    private struct Constants {
        static let duration: TimeInterval = 0.3
    }

    enum Direction {
        case present
        case dismiss
    }

    let direction: Direction

    init(direction: Direction) {
        self.direction = direction
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Constants.duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch direction {
        case .present:
            animatePresent(using: transitionContext)
        case .dismiss:
            animateDismiss(using: transitionContext)
        }
    }

    private func animatePresent(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        guard
            let toViewController = transitionContext.viewController(forKey: .to),
            let toView = transitionContext.view(forKey: .to)
        else {
            return
        }

        toView.frame = transitionContext.finalFrame(for: toViewController)
        toView.alpha = 0
        toView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        containerView.addSubview(toView)

        UIView.animate(
            withDuration: Constants.duration,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                toView.alpha = 1
                toView.transform = .identity
            },
            completion: { _ in
                transitionContext.completeTransition(true)
            })
    }

    private func animateDismiss(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else { return }

        UIView.animate(
            withDuration: Constants.duration,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                fromView.alpha = 0
                fromView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        },
            completion: { _ in
                transitionContext.completeTransition(true)
        })
    }
}
