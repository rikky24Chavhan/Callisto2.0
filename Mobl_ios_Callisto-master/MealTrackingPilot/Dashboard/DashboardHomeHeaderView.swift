//
//  DashboardHomeHeaderView.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/16/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

public final class DashboardHomeHeaderView: UIView {

    private struct Constants {
        static let logoImageSize: CGSize = UIDevice.current.isSmall ? CGSize(width: 48.0, height: 27.0) : CGSize(width: 59.0, height: 32.0)
        static let smallScreenDemologoImageToDayLabelSpace: CGFloat = 16.0
        static let logoImageToDayLabelSpace: CGFloat = -8.0
        static let dayLabelFontSize: Float = UIDevice.current.isSmallHeight ? 20.0 : 24.0
        static let messageViewHorizontalShadowInset: CGFloat = 2.0
        static let dayLabelToMealEventCountLabelSpacing: CGFloat = 2.0
        static let mealEventCountLabelToMessageViewSpacing: CGFloat = 20.0
    }

    // MARK: - Properties

    var currentDayText: String? {
        didSet {
            dayLabel.text = currentDayText

            // UI hack to make sure logo is not placed too high on small screen demo dashboard
            if UIDevice.current.isSmall && isDemo {
                _ = constrainView(logoView, above: self, withOffset: Constants.smallScreenDemologoImageToDayLabelSpace)
            } else {
                _ = constrainView(logoView, above: self, withOffset: Constants.logoImageToDayLabelSpace)
            }
        }
    }

    var mealEventCountText: NSAttributedString? {
        didSet {
            mealEventCountLabel.attributedText = mealEventCountText
        }
    }

    var suggestionMessage: NSAttributedString? {
        didSet {
            guard let suggestionMessage = suggestionMessage else { return }
            messageView.viewModel = DashboardHomeHeaderMessageViewModel(attributedText: suggestionMessage)
        }
    }

    private lazy var logoView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "lillyLogoWhite"))
        imageView.frame.size = Constants.logoImageSize
        return UIImageView(image: #imageLiteral(resourceName: "lillyLogoWhite"))
    }()

    private lazy var dayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.openSansBoldFont(size: Constants.dayLabelFontSize)
        label.textColor = .piPaleGrey
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    lazy var mealEventCountLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    lazy var messageView: MessageView = {
        let messageView = MessageView.fromNib()
        messageView.bubbleContainerTrailingConstraint.constant = 0
        messageView.bubbleContainer.trailingAnchor.constraint(equalTo: messageView.trailingAnchor).isActive = true
        messageView.translatesAutoresizingMaskIntoConstraints = false
        return messageView
    }()

    private var isDemo: Bool {
        return currentDayText == "DEMO"
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

    // MARK: - Actions

    private func setup() {
        addSubview(logoView)
        addSubview(dayLabel)
        addSubview(mealEventCountLabel)
        addSubview(messageView)

        // Constraints
        _ = constrainView(toMiddleHorizontally: logoView)
        dayLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        dayLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        mealEventCountLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        mealEventCountLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        messageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -Constants.messageViewHorizontalShadowInset).isActive = true
        messageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: Constants.messageViewHorizontalShadowInset).isActive = true
        dayLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        mealEventCountLabel.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: Constants.dayLabelToMealEventCountLabelSpacing).isActive = true
        messageView.topAnchor.constraint(equalTo: mealEventCountLabel.bottomAnchor, constant: Constants.mealEventCountLabelToMessageViewSpacing).isActive = true
        messageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

    }
}

fileprivate final class DashboardHomeHeaderMessageViewModel: ChatMessageViewModelProtocol {

    private struct Constants {
        static let inset: CGFloat = 22.0
        static let shadowInsetPadding: CGFloat = 3.0
        static let contentColor: UIColor = UIColor.white
    }

    var animationState: ChatMessageAnimationState = .idle
    let readingTime: TimeInterval = 0
    let bubbleOrientation: MessageBubbleOrientation = .incoming
    let isBubbleHighlighted: Bool = false
    let bubbleInsets: UIEdgeInsets = UIEdgeInsets.zero

    let typingEllipsisColor: UIColor = Constants.contentColor
    let textColor: UIColor = Constants.contentColor
    let contentInsets: UIEdgeInsets = UIEdgeInsets(top: Constants.inset, left: Constants.inset, bottom: Constants.inset + Constants.shadowInsetPadding, right: Constants.inset)

    let iconImage: UIImage? = nil
    let deliverySound: Sound? = nil

    let attributedText: NSAttributedString

    init(attributedText: NSAttributedString = NSAttributedString(string: "")) {
        self.attributedText = attributedText
    }

    func cachedCellHight() -> CGFloat? {
        return 84.0
    }

    func setCachedCellHeight(_ height: CGFloat?) {}
}
