//
//  BasicChatNodeGraph.swift
//  QuickGuru
//
//  Created by Andrew Dolce on 12/19/16.
//  Copyright © 2016 Eli Lilly. All rights reserved.
//

import Foundation

class BasicChatNodeGraph: ChatNodeGraph {
    private var nodesByIdentifier = [String: ChatNode]()

    var _startingIdentifier: String?

    func startingIdentifier() -> String {
        return _startingIdentifier ?? ""
    }

    func nodeForIdentifier(_ identifier: String) -> ChatNode? {
        return nodesByIdentifier[identifier]
    }

    func registerNode(_ node: ChatNode) {
        nodesByIdentifier[node.identifier] = node
    }
}
