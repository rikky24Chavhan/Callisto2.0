//
//  MessageView.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 5/2/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import Intrepid
import RxSwift

class MessageView: UIView {

    @IBOutlet weak var bubbleContainer: UIView!
    @IBOutlet weak var messageContentContainer: UIView!
    @IBOutlet weak var messageBubbleView: MessageBubbleView!
    @IBOutlet weak var typingEllipsisLabel: TypingEllipsisView!

    @IBOutlet weak var bubbleContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bubbleContainerTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bubbleContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bubbleContainerBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var bubbleImageFullWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var bubbleImageFullHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var messageContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageContainerTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var bubbleImageHorizontalPositionConstraint: NSLayoutConstraint!
    @IBOutlet weak var bubbleImageCompactHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bubbleImageCompactWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var bubbleContainerCompactHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bubbleContainerCompactWidthConstraint: NSLayoutConstraint!

    private var compactWidthConstraints: [NSLayoutConstraint] {
        return [
            bubbleImageCompactWidthConstraint,
            bubbleContainerCompactWidthConstraint
        ]
    }

    private var compactHeightConstraints: [NSLayoutConstraint] {
        return [
            bubbleImageCompactHeightConstraint,
            bubbleContainerCompactHeightConstraint,
        ]
    }

    private var bubbleImageFullSizeConstraints: [NSLayoutConstraint] {
        return [bubbleImageFullWidthConstraint, bubbleImageFullHeightConstraint]
    }

    private var messageContainerFullSizeConstraints: [NSLayoutConstraint] {
        return [messageContainerTopConstraint]
    }

    var viewModel: ChatMessageViewModelProtocol? = nil {
        didSet {
            configureFromViewModel()
        }
    }

    private var compactBubbleSize: CGSize = CGSize(width: 74, height: 48) {
        didSet {
            setNeedsUpdateConstraints()
        }
    }

    private var bubbleContainerInsets: UIEdgeInsets = UIEdgeInsets.zero {
        didSet {
            setNeedsUpdateConstraints()
        }
    }

    private var contentInsets: UIEdgeInsets = UIEdgeInsets.zero {
        didSet {
            setNeedsUpdateConstraints()
        }
    }

    private var messageContentView: UIView = UIView() {
        didSet {
            updateMessageContent(fromOldView: oldValue)
        }
    }

    private var contentConstraints = [NSLayoutConstraint]()

    private func configureFromViewModel() {
        guard let viewModel = viewModel else {
            return
        }

        bubbleContainerInsets = viewModel.bubbleInsets
        contentInsets = viewModel.contentInsets

        messageBubbleView.orientation = viewModel.bubbleOrientation
        messageBubbleView.highlighted = viewModel.isBubbleHighlighted
        typingEllipsisLabel.ellipsisColor = viewModel.typingEllipsisColor

        messageContentView = createContentView(with: viewModel)

        switch viewModel.animationState {
        case .idle:
            configureForIdleState()
        case .typing:
            configureForTypingState()
        case .sliding:
            configureForSlidingState()
        case .expanding:
            configureForExpandingState()
        }

        invalidateIntrinsicContentSize()
    }

    // MARK: Message Content

    private func createContentView(with messageViewModel: ChatMessageViewModelProtocol) -> UIView {
        let attributedText = messageViewModel.attributedText

        if let _ = messageViewModel.iconImage {
            return createIconContentView(with: messageViewModel)
        } else {
            return createTextContentView(with: attributedText)
        }
    }

    private func createTextContentView(with attributedString: NSAttributedString) -> UIView {
        let label = UILabel(frame: .zero)
        label.attributedText = attributedString
        label.numberOfLines = 0
        return label
    }

    private func createIconContentView(with messageViewModel: ChatMessageViewModelProtocol) -> UIView {
        let contentView = IconMessageContentView.ip_fromNib()
        contentView.messageViewModel = messageViewModel
        return contentView
    }

    private func updateMessageContent(fromOldView oldView: UIView) {
        guard messageContentView != oldView else {
            return
        }

        oldView.removeFromSuperview()
        messageContentContainer.addSubview(messageContentView)

        setNeedsUpdateConstraints()
    }

    private func configureMessageContentConstraints() {
        guard messageContentView.superview == messageContentContainer else {
            return
        }

        messageContentView.translatesAutoresizingMaskIntoConstraints = false

        contentConstraints.forEach { $0.isActive = false }

        contentConstraints = [
            messageContentContainer.leftAnchor.constraint(equalTo: messageContentView.leftAnchor, constant: -contentInsets.left),
            messageContentContainer.rightAnchor.constraint(equalTo: messageContentView.rightAnchor, constant: contentInsets.right),
            messageContentContainer.topAnchor.constraint(equalTo: messageContentView.topAnchor, constant: -contentInsets.top),
            messageContentContainer.bottomAnchor.constraint(equalTo: messageContentView.bottomAnchor, constant: contentInsets.bottom)
        ]

        contentConstraints.forEach { $0.isActive = true }
    }

    // MARK: Constraints

    override func updateConstraints() {
        super.updateConstraints()

        configureCompactSizeConstraints()
        configureBubbleContainerConstraints()
        configureMessageContentConstraints()
    }

    private func configureCompactSizeConstraints() {
        for constraint in compactWidthConstraints {
            constraint.constant = compactBubbleSize.width
        }
        for constraint in compactHeightConstraints {
            constraint.constant = compactBubbleSize.height
        }
    }

    private func configureBubbleContainerConstraints() {
        guard let viewModel = viewModel else {
            return
        }

        // Remove old constraints
        removeConstraints([
            bubbleContainerLeadingConstraint,
            bubbleContainerTrailingConstraint
        ])

        let newLeadingConstraint = NSLayoutConstraint(
            item: bubbleContainer,
            attribute: .leading,
            relatedBy: (viewModel.bubbleOrientation == .incoming) ? .equal : .greaterThanOrEqual,
            toItem: self,
            attribute: .leading,
            multiplier: 1.0,
            constant: bubbleContainerInsets.left
        )

        let newTrailingConstraint = NSLayoutConstraint(
            item: self,
            attribute: .trailing,
            relatedBy: (viewModel.bubbleOrientation == .outgoing) ? .equal : .greaterThanOrEqual,
            toItem: bubbleContainer,
            attribute: .trailing,
            multiplier: 1.0,
            constant: bubbleContainerInsets.right
        )

        addConstraints([
            newLeadingConstraint,
            newTrailingConstraint,
        ])

        bubbleContainerLeadingConstraint = newLeadingConstraint
        bubbleContainerTrailingConstraint = newTrailingConstraint
        bubbleContainerTopConstraint.constant = bubbleContainerInsets.top
        bubbleContainerBottomConstraint.constant = bubbleContainerInsets.bottom

        bubbleContainer.removeConstraint(bubbleImageHorizontalPositionConstraint)

        let newBubblePositionConstraint: NSLayoutConstraint
        switch viewModel.bubbleOrientation {
        case .incoming:
            newBubblePositionConstraint = bubbleContainer.leadingAnchor.constraint(equalTo: messageBubbleView.leadingAnchor)
        case .outgoing:
            newBubblePositionConstraint = bubbleContainer.trailingAnchor.constraint(equalTo: messageBubbleView.trailingAnchor)
        }

        bubbleContainer.addConstraint(newBubblePositionConstraint)

        bubbleImageHorizontalPositionConstraint = newBubblePositionConstraint
    }

    private func setBubbleImageConstraints(compact: Bool) {
        let fullSizePriority: UILayoutPriority = compact ? .defaultLow : .defaultHigh
        for constraint in bubbleImageFullSizeConstraints {
            constraint.priority = fullSizePriority
        }
    }

    private func setMessageContainerConstraints(compact: Bool) {
        let fullSizePriority: UILayoutPriority = compact ? .defaultLow : .defaultHigh
        for constraint in messageContainerFullSizeConstraints {
            constraint.priority = fullSizePriority
        }
    }

    // MARK: Animation

    private func configureForTypingState() {
        messageContentView.alpha = 0
        typingEllipsisLabel.alpha = 1
        setBubbleImageConstraints(compact: true)
        setMessageContainerConstraints(compact: true)
        setNeedsLayout()
    }

    private func configureForSlidingState() {
        messageContentView.alpha = 0
        typingEllipsisLabel.alpha = 1
        setBubbleImageConstraints(compact: true)
        setMessageContainerConstraints(compact: false)
        setNeedsLayout()
    }

    private func configureForExpandingState() {
        configureForSlidingState()
    }

    private func configureForIdleState() {
        messageContentView.alpha = 1
        typingEllipsisLabel.alpha = 0
        setBubbleImageConstraints(compact: false)
        setMessageContainerConstraints(compact: false)
        setNeedsLayout()
    }

    func willDisplay() {
        guard viewModel?.animationState == .expanding else {
            return
        }
        self.animateToFullLayout(completion: { _ in
            self.viewModel?.deliverySound?.play()
        })
    }

    private func animateToFullLayout(duration: TimeInterval = 0.4, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {_ in}) {
        layoutIfNeeded()
        setBubbleImageConstraints(compact: false)

        UIView.animate(withDuration: duration * 0.75, animations: {
            self.typingEllipsisLabel.alpha = 0
            self.layoutIfNeeded()
        })
        UIView.animate(withDuration: duration * 0.75, delay: 0.25, animations: {
            self.messageContentView.alpha = 1
        }, completion: completion)
    }

    // MARK: Height Calculation

    func heightThatFits(width boundingWidth: CGFloat, with viewModel: ChatMessageViewModelProtocol) -> CGFloat {
        self.viewModel = viewModel

        if viewModel.animationState == .typing {
            return minimumHeight
        }

        let boundingSize = CGSize(width: boundingWidth, height: UIView.layoutFittingCompressedSize.height)
        let fittingSize = systemLayoutSizeFitting(boundingSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        return fittingSize.height
    }

    var minimumHeight: CGFloat {
        return compactBubbleSize.height + bubbleContainerInsets.top + bubbleContainerInsets.bottom
    }
}
