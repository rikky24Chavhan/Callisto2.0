//
//  ChatMessageViewModel.swift
//  QuickGuru
//
//  Created by Andrew Dolce on 12/10/16.
//  Copyright © 2016 Eli Lilly. All rights reserved.
//

import UIKit
import RxSwift

fileprivate let defaultIncomingBubbleInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 34)
fileprivate let defaultOutgoingBubbleInsets = UIEdgeInsets(top: 8, left: 34, bottom: 8, right: 16)
fileprivate let defaultContentInsets = UIEdgeInsets(top: 18, left: 20, bottom: 20, right: 20)

fileprivate let bubbleImageFudgeFactorInsets = UIEdgeInsets(top: 2, left: 4, bottom: 6, right: 4)

class ChatMessageViewModel: ChatMessageViewModelProtocol {
    let message: Message

    var animationState: ChatMessageAnimationState

    var isHighlighted: Bool

    var readingTime: TimeInterval {
        return message.estimatedReadingTime
    }

    var bubbleOrientation: MessageBubbleOrientation {
        return message.sender == .guru ? .incoming : .outgoing
    }

    var isBubbleHighlighted: Bool {
        return isHighlighted
    }

    var bubbleInsets: UIEdgeInsets {
        let insets = bubbleOrientation == .incoming ? defaultIncomingBubbleInsets : defaultOutgoingBubbleInsets
        return insets - bubbleImageFudgeFactorInsets
    }

    var typingEllipsisColor: UIColor {
        return textColor
    }

    var textColor: UIColor {
        return isHighlighted ? UIColor.piDenim : UIColor.white
    }

    private var textSize: Float {
        return 16
    }

    private var font: UIFont {
        return (message.textStyle == .bold) ? UIFont.openSansBoldFont(size: textSize) : UIFont.openSansFont(size: textSize)
    }

    var attributedText: NSAttributedString {
        return NSAttributedString(string: message.text, attributes: [
            NSAttributedStringKey.font: font,
            NSAttributedStringKey.foregroundColor: textColor
        ])
    }

    var iconImage: UIImage? {
        guard let iconName = message.iconName, let icon = MessageIcon(rawValue: iconName) else {
            return nil
        }

        if isHighlighted {
            return icon.highlightedImage ?? icon.image
        }
        return icon.image
    }

    var contentInsets: UIEdgeInsets {
        return defaultContentInsets + bubbleImageFudgeFactorInsets
    }

    init(message: Message, animationState: ChatMessageAnimationState = .idle, isHighlighted: Bool = false) {
        self.message = message
        self.animationState = animationState
        self.isHighlighted = isHighlighted
    }

    // MARK: Cached Height

    private var cachedTypingHeight: CGFloat? = 56
    private var cachedHeight: CGFloat?

    func cachedCellHight() -> CGFloat? {
        switch animationState {
        case .typing:
            return cachedTypingHeight
        default:
            return cachedHeight
        }
    }

    func setCachedCellHeight(_ height: CGFloat?) {
        switch animationState {
        case .typing:
            cachedTypingHeight = height
        default:
            cachedHeight = height
        }
    }

    // MARK: Sound

    var deliverySound: Sound? {
        if message.sender == .user {
            return .messageSent
        } else if isHighlighted {
            // Chatbot sounds get a little repetitive, so we only play received sounds for highlighted messages
            return .messageReceived
        }
        return nil
    }
}

extension ChatMessageViewModel: Equatable {
    static func ==(_ lhs: ChatMessageViewModel, _ rhs: ChatMessageViewModel) -> Bool {
        return lhs.message.identifier == rhs.message.identifier
    }
}

fileprivate enum MessageIcon: String {
    case monitor
    case talking

    struct ImageSet {
        let image: UIImage?
        let highlightedImage: UIImage?
    }

    private static let imageSets: [MessageIcon: ImageSet] = [
        .monitor: ImageSet(image: #imageLiteral(resourceName: "chatIconMonitorWhite"), highlightedImage: #imageLiteral(resourceName: "chatIconMonitorBlue")),
        .talking: ImageSet(image: #imageLiteral(resourceName: "chatIconTalkWhite"), highlightedImage: #imageLiteral(resourceName: "chatIconTalkBlue")),
    ]

    var image: UIImage? {
        return MessageIcon.imageSets[self]?.image
    }

    var highlightedImage: UIImage? {
        return MessageIcon.imageSets[self]?.highlightedImage
    }
}

// MARK: - UIEdgeInsets helpers

fileprivate func +(lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> UIEdgeInsets {
    return UIEdgeInsets(
        top: lhs.top + rhs.top,
        left: lhs.left + rhs.left,
        bottom: lhs.bottom + rhs.bottom,
        right: lhs.right + rhs.right
    )
}

fileprivate func -(lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> UIEdgeInsets {
    return UIEdgeInsets(
        top: lhs.top - rhs.top,
        left: lhs.left - rhs.left,
        bottom: lhs.bottom - rhs.bottom,
        right: lhs.right - rhs.right
    )
}
