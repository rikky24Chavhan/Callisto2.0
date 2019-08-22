//
//  ChatToChatCompletionTransitionAnimator.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 5/2/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

class ChatToChatCompletionTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard
            let toViewController = transitionContext?.viewController(forKey: .to) as? ChatCompletionViewController,
            let fromViewController = transitionContext?.viewController(forKey: .from) as? ChatViewController
        else {
            return 0.0
        }

        return fromViewController.totalOutroAnimationDuration() + toViewController.totalIntroAnimationTime()
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromViewController = transitionContext.viewController(forKey: .from) as? ChatViewController,
            let toViewController = transitionContext.viewController(forKey: .to) as? ChatCompletionViewController,
            let fromView = fromViewController.view,
            let toView = toViewController.view
        else {
            print("ChatToChatCompletionTransitionAnimator received context with unexpected controllers.")
            transitionContext.completeTransition(false)
            return
        }

        transitionContext.containerView.addSubview(toView)
        transitionContext.containerView.addSubview(fromView)
        fromView.frame = transitionContext.initialFrame(for: fromViewController)
        toView.frame = transitionContext.finalFrame(for: toViewController)

        toViewController.prepareForIntroAnimation()

        fromViewController.performOutroAnimation(completion: { _ in
            toViewController.performIntroAnimation(completion: { completed in
                transitionContext.completeTransition(completed)
            })
        })
    }
}
