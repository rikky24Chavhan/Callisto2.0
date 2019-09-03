//
//  ChatMessageTableViewCell.swift
//  QuickGuru
//
//  Created by Andrew Dolce on 12/9/16.
//  Copyright © 2016 Eli Lilly. All rights reserved.
//

import UIKit
import Intrepid

class ChatMessageTableViewCell: UITableViewCell {
    private var messageView: MessageView?

    var viewModel: ChatMessageViewModelProtocol? = nil {
        didSet {
            configureFromViewModel()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        let messageView = MessageView.ip_fromNib()
        messageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageView)
        contentView.constrainView(toAllEdges: messageView)

        self.messageView = messageView
    }

    private func configureFromViewModel() {
        guard let viewModel = viewModel, let messageView = messageView else {
            return
        }

        messageView.viewModel = viewModel
    }

    // MARK: Animation

    func willDisplay() {
        messageView?.willDisplay()
    }

    // MARK: Height Calculation

    func heightThatFits(width boundingWidth: CGFloat, with viewModel: ChatMessageViewModelProtocol) -> CGFloat {
        let height = messageView?.heightThatFits(width: boundingWidth, with: viewModel) ?? 0
        return height
    }

    var minimumHeight: CGFloat {
        return messageView?.minimumHeight ?? 0
    }

    class func createSizingCell() -> ChatMessageTableViewCell {
        return self.ip_fromNib()
    }
}
