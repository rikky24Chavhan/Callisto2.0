//
//  ChatDriver.swift
//  QuickGuru
//
//  Created by Andrew Dolce on 12/12/16.
//  Copyright © 2016 Eli Lilly. All rights reserved.
//

import Foundation

protocol ChatControllerDelegate: class {
    func chatControllerIsReady(_ chatController: ChatController)
    func chatController(_ chatController: ChatController, didFinishExecutingNode node: ChatNode)
}

protocol ChatController {
    var chatDelegate: ChatControllerDelegate? { get set }
    func executeNode(_ node: ChatNode)
}

class ChatDriver: ChatControllerDelegate {
    private(set) var chatController: ChatController
    private(set) var asyncDispatcher: AsyncDispatcherProtocol
    let nodeGraph: ChatNodeGraph
    var completion: (() -> Void)?

    private(set) var currentNode: ChatNode?

    init(
        chatController: ChatController,
        asyncDispatcher: AsyncDispatcherProtocol = AsyncDispatcher(),
        nodeGraph: ChatNodeGraph,
        completion: (() -> ())?) {
        self.chatController = chatController
        self.asyncDispatcher = asyncDispatcher
        self.nodeGraph = nodeGraph
        self.completion = completion

        self.chatController.chatDelegate = self
    }

    func beginExecution() {
        guard let startingNode = nodeGraph.nodeForIdentifier(nodeGraph.startingIdentifier()) else {
            return
        }

        executeNode(startingNode)
    }

    func executeNode(_ node: ChatNode) {
        currentNode = node

        chatController.executeNode(node)
    }

    // MARK: ChatControllerDelegate

    func chatControllerIsReady(_ chatController: ChatController) {
        beginExecution()
    }

    func chatController(_ chatController: ChatController, didFinishExecutingNode node: ChatNode) {
        // TODO: Compare for equality with current node

        guard node.canContinue else {
            return
        }
        guard let nextIdentifier = node.nextNodeIdentifier(), let nextNode = nodeGraph.nodeForIdentifier(nextIdentifier) else {
            asyncDispatcher.after(0.5) {
                self.completion?()
            }
            return
        }

        executeNode(nextNode)
    }
}
