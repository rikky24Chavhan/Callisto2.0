//
//  UserConfirmationNode.swift
//  QuickGuru
//
//  Created by Andrew Dolce on 12/12/16.
//  Copyright © 2016 Eli Lilly. All rights reserved.
//

import Foundation

struct UserConfirmationNode: ChatNode {
    let identifier: String
    private var nextIdentifier: String?

    let callToActionText: String

    private(set) var confirmed = false

    init(identifier: String, nextIdentifier: String? = nil, callToActionText: String) {
        self.identifier = identifier
        self.nextIdentifier = nextIdentifier
        self.callToActionText = callToActionText
    }

    var canContinue: Bool {
        return confirmed
    }

    func nextNodeIdentifier() -> String? {
        return nextIdentifier
    }

    mutating func didReceiveConfirmation() {
        confirmed = true
    }
}
