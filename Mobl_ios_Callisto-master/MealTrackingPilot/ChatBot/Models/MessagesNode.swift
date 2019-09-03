//
//  MessagesNode.swift
//  QuickGuru
//
//  Created by Andrew Dolce on 12/12/16.
//  Copyright © 2016 Eli Lilly. All rights reserved.
//

import Foundation

struct MessagesNode: ChatNode {
    let identifier: String
    let sender: MessageSender
    let messages: [Message]
    private var nextIdentifier: String?

    private(set) var canContinue: Bool = false

    init(identifier: String, sender: MessageSender, messages: [Message], nextIdentifier: String? = nil) {
        self.identifier = identifier
        self.sender = sender
        self.messages = messages
        self.nextIdentifier = nextIdentifier
    }

    mutating func didDeliverAllMessages() {
        canContinue = true
    }

    func nextNodeIdentifier() -> String? {
        return nextIdentifier
    }
}
