//
//  ChatNodeGraphJSONLoader.swift
//  QuickGuru
//
//  Created by Andrew Dolce on 12/19/16.
//  Copyright © 2016 Eli Lilly. All rights reserved.
//

import Foundation

enum NodeGraphParseError: Error {
    case FileNotFound
    case UnexpectedJSONStructure
    case MissingNodeDefinitions
}

enum ChatNodeParseError: Error {
    case InvalidNodeEntry
    case UnknownEntryType
    case MissingIdentifier
}

enum MessageParseError: Error {
    case MissingText
    case InvalidHighlightProperties
}

enum UserConfirmationParseError: Error {
    case MissingCallToActionText
}

enum UserPermissionsParseError: Error {
    case MissingPermissionsType
}

private class ChatNodeGraphJSONLoader {

    private let graph: BasicChatNodeGraph

    init(graph: BasicChatNodeGraph) {
        self.graph = graph
    }

    func loadFromFile(fileName: String, bundle: Bundle = Bundle.main) throws {
        guard let path = bundle.path(forResource: fileName, ofType: "json") else {
            throw NodeGraphParseError.FileNotFound
        }

        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)

        try loadFromJSON(data)
    }

    private func loadFromJSON(_ json: Data) throws {
        let parsed = try JSONSerialization.jsonObject(with: json, options: [])

        guard let top = parsed as? [String: Any] else {
            throw NodeGraphParseError.UnexpectedJSONStructure
        }

        guard let nodeEntries = top["nodes"] as? [Any] else {
            throw NodeGraphParseError.MissingNodeDefinitions
        }

        nodeEntries.compactMap { try? self.nodeFromEntry($0) }.forEach { node in
            self.graph.registerNode(node)
        }

        if let startingIdentifier = top["start"] as? String {
            graph._startingIdentifier = startingIdentifier
        }
    }

    private func nodeFromEntry(_ nodeEntry: Any) throws -> ChatNode {
        guard let entry = nodeEntry as? [String: Any] else {
            throw ChatNodeParseError.InvalidNodeEntry
        }

        let parsableTypes: [ChatNodeParsable.Type] = [
            MessagesNode.self,
            UserConfirmationNode.self,
            UserPermissionsNode.self,
        ]
        for type in parsableTypes {
            if let node = try? type.nodeFromJsonEntry(entry) {
                return node
            }
        }

        throw ChatNodeParseError.UnknownEntryType
    }
}

extension BasicChatNodeGraph {
    convenience init(jsonFileName: String, bundle: Bundle = Bundle.main) {
        self.init()

        do {
            let loader = ChatNodeGraphJSONLoader(graph: self)
            try loader.loadFromFile(fileName: jsonFileName, bundle: bundle)
        } catch {
            print("Error loading ChatBot graph: \(error)")
        }
    }
}

// MARK: - Parsable Nodes

fileprivate protocol ChatNodeParsable {
    static func nodeFromJsonEntry(_ entry: [String: Any]) throws -> ChatNode
}

// MARK: Messages Node

extension MessagesNode: ChatNodeParsable {
    static func nodeFromJsonEntry(_ entry: [String : Any]) throws -> ChatNode {
        return try messagesNodeFromEntry(entry)
    }

    private static func messagesNodeFromEntry(_ nodeEntry: [String: Any]) throws -> ChatNode {
        guard let identifier = nodeEntry["id"] as? String else {
            throw ChatNodeParseError.MissingIdentifier
        }
        guard
            let senderText = nodeEntry["sender"] as? String,
            let sender = MessageSender(rawValue: senderText)
        else {
            throw ChatNodeParseError.InvalidNodeEntry
        }
        guard let messageEntries = nodeEntry["messages"] as? [[String: Any]] else {
            throw ChatNodeParseError.InvalidNodeEntry
        }

        let messages = messageEntries.compactMap { try? self.messageFromJSON($0, sender: sender) }
        let nextIdentifier = nodeEntry["next"] as? String

        return MessagesNode(identifier: identifier, sender: sender, messages: messages, nextIdentifier: nextIdentifier)
    }

    private static func messageFromJSON(_ messageJSON: [String: Any], sender: MessageSender) throws -> Message {
        guard let text = messageJSON["text"] as? String else {
            throw MessageParseError.MissingText
        }

        var textStyle: MessageTextStyle = .normal
        if let styleName = messageJSON["style"] as? String {
            textStyle = MessageTextStyle(rawValue: styleName) ?? .normal
        }

        let iconName = messageJSON["icon"] as? String

        var highlightCondition: MessageHighlightCondition? = nil
        if let highlightJSON = messageJSON["highlight"] as? [String: Any] {
            highlightCondition = try MessageHighlightCondition(json: highlightJSON)
        }

        let extraReadingTime = messageJSON["extraReadingTime"] as? TimeInterval ?? TimeInterval(0)

        return Message(
            text: text,
            textStyle: textStyle,
            iconName: iconName,
            highlightCondition: highlightCondition,
            extraReadingTime: extraReadingTime,
            sender: sender
        )
    }
}

fileprivate extension MessageHighlightCondition {
    init(json: [String: Any]) throws {
        let condition: MessageHighlightCondition
        if let nodeIdentifier = json["untilAfter"] as? String {
            condition = .untilAfter(nodeIdentifier: nodeIdentifier)
        } else if let _ = json["always"] {
            condition = .always
        } else {
            throw MessageParseError.InvalidHighlightProperties
        }

        self = condition
    }
}

// MARK: User Confirmation Node

extension UserConfirmationNode: ChatNodeParsable {
    static func nodeFromJsonEntry(_ entry: [String : Any]) throws -> ChatNode {
        return try confirmationNodeFromEntry(entry)
    }

    private static func confirmationNodeFromEntry(_ entry: [String: Any]) throws -> ChatNode {
        guard let identifier = entry["id"] as? String else {
            throw ChatNodeParseError.MissingIdentifier
        }

        let nextIdentifier = entry["next"] as? String

        guard let callToActionText = entry["callToActionText"] as? String else {
            throw UserConfirmationParseError.MissingCallToActionText
        }

        return UserConfirmationNode(
            identifier: identifier,
            nextIdentifier: nextIdentifier,
            callToActionText: callToActionText
        )
    }
}

// MARK: User Permissions Node

extension UserPermissionsNode: ChatNodeParsable {
    static func nodeFromJsonEntry(_ entry: [String : Any]) throws -> ChatNode {
        return try permissionsNodeFromEntry(entry)
    }

    private static func permissionsNodeFromEntry(_ entry: [String: Any]) throws -> ChatNode {
        guard let identifier = entry["id"] as? String else {
            throw ChatNodeParseError.MissingIdentifier
        }
        let nextIdentifier = entry["next"] as? String

        guard
            let permissionsTypeRaw = entry["requestPermissions"] as? String,
            let permissionsType = ChatPermissionsType(rawValue: permissionsTypeRaw)
        else {
            throw UserPermissionsParseError.MissingPermissionsType
        }

        return UserPermissionsNode(identifier: identifier, nextIdentifier: nextIdentifier, permissionsType: permissionsType)
    }
}
