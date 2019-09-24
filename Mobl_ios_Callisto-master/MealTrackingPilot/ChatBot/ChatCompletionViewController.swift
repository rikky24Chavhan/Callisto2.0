//
//  ChatCompletionViewController.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 5/1/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

class ChatCompletionViewController: UIViewController {

    private struct Constants {
        static let messageViewTopMargin: CGFloat = 40

        static let messageFadeInDelay: TimeInterval = 0.5
        static let messageFadeInDuration: TimeInterval = 0.3
        static let messageExpandingDuration: TimeInterval = 0.3

        static let iconFadeInDelay: TimeInterval = 0.8
        static let iconFadeInDuration: TimeInterval = 1.0

        static let confirmationButtonFadeInDelay: TimeInterval = 1.2
        static let confirmationButtonFadeInDuration: TimeInterval = 0.3
    }

    @IBOutlet weak var backgroundGradientView: GradientView!
    @IBOutlet weak var thumbsUpIcon: UIImageView!
    @IBOutlet weak var confirmationButton: GradientButton!

    private let viewModel: ChatCompletionViewModel
    private var messageView: MessageView?

    init(viewModel: ChatCompletionViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()
        setupBackgroundGradient()
        setupConfirmationButton()
    }

    private func setupNavigationItem() {
        navigationItem.hidesBackButton = true
    }

    // MARK: - Background View

    private func setupBackgroundGradient() {
        backgroundGradientView.direction = .topLeftToBottomRight
        backgroundGradientView.colors = [
            UIColor.piMetallicBlue,
            UIColor.piDreBlue,
            UIColor.piGreyblueTwo,
            UIColor.piLightBlueGrey,
        ]
        backgroundGradientView.locations = [0.0, 0.25, 0.75, 1.0]
    }

    // MARK: - Confirmation Button

    private func setupConfirmationButton() {
        confirmationButton.cornerRadius = 25
        confirmationButton.gradientDirection = .vertical
        confirmationButton.gradientColors = [
            UIColor.piDarkSkyBlue,
            UIColor.piCornflower
        ]
    }

    // MARK: - Message Bubble

    private func setupMessageView() {
        let messageView = MessageView.fromNib()
        messageView.translatesAutoresizingMaskIntoConstraints = false
        messageView.viewModel = viewModel.slidingViewModel()
        messageView.alpha = 0

        view.addSubview(messageView)
        messageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        messageView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.messageViewTopMargin).isActive = true

        self.messageView = messageView
    }

    private func animateInMessage(delay: TimeInterval = Constants.messageFadeInDelay, completion: ((Bool) -> Void)? = nil) {
        guard let messageView = messageView else {
            return
        }

        UIView.animate(withDuration: Constants.messageFadeInDuration, delay: delay, animations: {
            messageView.alpha = 1.0
        }, completion: { _ in
            messageView.viewModel = self.viewModel.expandingViewModel()
            messageView.willDisplay()
            self.view.setNeedsLayout()

            UIView.animate(withDuration: Constants.messageExpandingDuration, animations: {
                self.view.layoutIfNeeded()
            }, completion: completion)
        })
    }

    // MARK: - Intro Animation

    private func totalMessageFadeInTime() -> TimeInterval {
        return
            Constants.messageFadeInDelay +
            Constants.messageFadeInDuration +
            Constants.messageExpandingDuration
    }

    private func totalIconFadeInTime() -> TimeInterval {
        return Constants.iconFadeInDelay + Constants.iconFadeInDuration
    }

    private func totalConfirmationButtonFadeInTime() -> TimeInterval {
        return Constants.confirmationButtonFadeInDelay + Constants.confirmationButtonFadeInDuration
    }

    func totalIntroAnimationTime() -> TimeInterval {
        return totalMessageFadeInTime() + max(totalIconFadeInTime(), totalConfirmationButtonFadeInTime())
    }

    func prepareForIntroAnimation() {
        setupMessageView()
        thumbsUpIcon.alpha = 0.0
        thumbsUpIcon.transform = CGAffineTransform(scaleX: 0.7, y: 0.7).rotated(by: CGFloat(Double.pi / 12.0))
        confirmationButton.alpha = 0.0
    }

    func performIntroAnimation(completion: ((Bool) -> Void)? = nil) {
        animateInMessage(completion: { _ in
            self.fadeInIcon()
            self.fadeInConfirmationButton(completion: completion)
        })
    }

    private func fadeInIcon(completion: ((Bool) -> Void)? = nil) {
        UIView.animate(
            withDuration: Constants.iconFadeInDuration,
            delay: Constants.iconFadeInDelay,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 1.0,
            options: [],
            animations: {
                self.thumbsUpIcon.transform = .identity
                self.thumbsUpIcon.alpha = 1.0
            },
            completion: completion
        )
    }

    private func fadeInConfirmationButton(completion: ((Bool) -> Void)? = nil) {
        UIView.animate(
            withDuration: Constants.confirmationButtonFadeInDuration,
            delay: Constants.confirmationButtonFadeInDelay,
            options: [],
            animations: {
                self.confirmationButton.alpha = 1.0
            },
            completion: completion
        )
    }

    // MARK: - Button Hide

    private func fadeOutButton(animated: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.confirmationButton.alpha = 0
        }
    }

    // MARK: - Action

    @IBAction func continueButtonPressed(_ sender: UIButton) {
        fadeOutButton(animated: true)
        viewModel.didPressContinue()
    }
}
