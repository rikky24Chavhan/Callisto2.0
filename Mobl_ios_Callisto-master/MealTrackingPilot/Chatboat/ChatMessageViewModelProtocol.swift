//
//  ChatMessageViewModelProtocol.swift
//  QuickGuru
//
//  Created by Andrew Dolce on 12/12/16.
//  Copyright © 2016 Eli Lilly. All rights reserved.
//

import UIKit
import RxSwift

enum ChatMessageAnimationState {
    case idle
    case typing
    case sliding
    case expanding
}

protocol ChatMessageViewModelProtocol: class {
    var animationState: ChatMessageAnimationState { get set }
    var readingTime: TimeInterval { get }
    var bubbleOrientation: MessageBubbleOrientation { get }
    var isBubbleHighlighted: Bool { get }
    var bubbleInsets: UIEdgeInsets { get }

    var typingEllipsisColor: UIColor { get }
    var textColor: UIColor { get }
    var attributedText: NSAttributedString { get }
    var contentInsets: UIEdgeInsets { get }

    var iconImage: UIImage? { get }

    var deliverySound: Sound? { get }

    func cachedCellHight() -> CGFloat?
    func setCachedCellHeight(_ height: CGFloat?)
}

extension ChatMessageViewModelProtocol {
    var isTyping: Bool {
        return animationState == .typing
    }

    var isSliding: Bool {
        return animationState == .sliding
    }

    var isExpanding: Bool {
        return animationState == .expanding
    }
}
