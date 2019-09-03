//
//  MessageBubbleView.swift
//  QuickGuru
//
//  Created by Andrew Dolce on 12/9/16.
//  Copyright © 2016 Eli Lilly. All rights reserved.
//

import UIKit

enum MessageBubbleOrientation {
    case incoming
    case outgoing
}

class MessageBubbleView: UIView {
    var orientation: MessageBubbleOrientation = .incoming {
        didSet {
            updateBubbleImage()
        }
    }

    var highlighted: Bool = false {
        didSet {
            updateBubbleImage()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        setupImageView()
    }

    private var imageView = UIImageView()

    private func setupImageView() {
        addSubview(imageView)
        constrainView(toAllEdges: imageView)
    }

    private func updateBubbleImage() {
        imageView.image = MessageBubbleFactory.bubbleImage(forOrientation: orientation, highlighted: highlighted)
        imageView.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .vertical)
    }
}

fileprivate class MessageBubbleFactory {
    static func bubbleImage(forOrientation orientation: MessageBubbleOrientation, highlighted: Bool) -> UIImage? {
        switch orientation {
        case .incoming:
            return highlighted ? incomingHighlightedImage() : incomingImage()
        case .outgoing:
            return outgoingImage()
        }
    }

    private static func incomingImage() -> UIImage? {
        return #imageLiteral(resourceName: "chatBubbleLeftDefault")
    }

    private static func incomingHighlightedImage() -> UIImage? {
        return #imageLiteral(resourceName: "chatBubbleLeftHighlight")
    }

    private static func outgoingImage() -> UIImage? {
        return #imageLiteral(resourceName: "chatBubbleRightDefault")
    }
}
