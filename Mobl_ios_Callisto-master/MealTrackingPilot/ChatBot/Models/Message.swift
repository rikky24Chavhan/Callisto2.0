//
//  Message.swift
//  QuickGuru
//
//  Created by Andrew Dolce on 12/9/16.
//  Copyright © 2016 Eli Lilly. All rights reserved.
//

import Foundation

enum MessageSender: String {
    case user
    case guru
}

enum MessageTextStyle: String {
    case normal
    case bold
}

enum MessageHighlightCondition {
    case always
    case untilAfter(nodeIdentifier: String)
}

struct Message {
    let identifier: String

    let text: String
    let textStyle: MessageTextStyle
    let iconName: String?
    let highlightCondition: MessageHighlightCondition?

    let sender: MessageSender

    var extraReadingTime: TimeInterval

    init(
        text: String,
        textStyle: MessageTextStyle = .normal,
        iconName: String? = nil,
        highlightCondition: MessageHighlightCondition? = nil,
        extraReadingTime: TimeInterval = 0,
        sender: MessageSender
    ) {
        self.identifier = Message.newIdentifier()
        self.text = text
        self.textStyle = textStyle
        self.iconName = iconName
        self.highlightCondition = highlightCondition
        self.extraReadingTime = extraReadingTime
        self.sender = sender
    }

    private static var nextIdentifier = 0

    private static func newIdentifier() -> String {
        let identifier = nextIdentifier
        nextIdentifier += 1
        return "\(identifier)"
    }

    // MARK: Reading Time

    var estimatedReadingTime: TimeInterval {
        let wordsPerMinute = 300.0
        let averageCharactersPerWord = 4.0
        let charactersPerSecond = wordsPerMinute * averageCharactersPerWord / 60.0
        return TimeInterval(Double(text.count) / charactersPerSecond) + extraReadingTime
    }
}
