//
//  ChatViewModel.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/18/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import Intrepid
import RxSwift

enum ChatTableItem {
    case spacer
    case message(viewModel: ChatMessageViewModelProtocol)
}

enum ChatTableState {
    case idle
    case inserting(messageViewModel: ChatMessageViewModelProtocol)
    case updatingHighlights(indexPaths: [IndexPath])
}

fileprivate extension ChatTableState {
    var needsBottomSpacer: Bool {
        switch self {
        case .inserting(let messageViewModel):
            if messageViewModel.animationState == .typing {
                return false
            }
        default:
            break
        }
        return true
    }
}

class ChatViewModel: ChatController {
    private let healthKitPermissionsController: PermissionRequestController
    private let locationPermissionsController: PermissionRequestController

    private let asyncDispatcher: AsyncDispatcherProtocol

    private var messageViewModels = [ChatMessageViewModel]()

    private var _state: Variable<ChatTableState> = Variable(.idle)

    var state: Observable<ChatTableState> {
        return _state.asObservable()
    }

    private var _callToActionText: Variable<String?> = Variable(nil)

    var callToActionText: Observable<String?> {
        return _callToActionText.asObservable()
    }

    var tableItems: [ChatTableItem] {
        let messageItems = messageViewModels.map { ChatTableItem.message(viewModel: $0) }
        if _state.value.needsBottomSpacer {
            return [ .spacer ] + messageItems
        } else {
            return messageItems
        }
    }

    private(set) var pendingMessages: [Message] = []

    weak var chatDelegate: ChatControllerDelegate?

    private var currentNode: ChatNode?

    private var completedNodes = [ChatNode]()

    func insert(message: Message) {
        insert(messages: [message])
    }

    func insert(messages: [Message]) {
        pendingMessages.append(contentsOf: messages)

        switch _state.value {
        case .idle:
            beginNextInsertion()
        default:
            break
        }
    }

    // MARK: - Lifecycle

    init(
        healthKitPermissionsController: PermissionRequestController,
        locationPermissionsController: PermissionRequestController,
        asyncDispatcher: AsyncDispatcherProtocol = AsyncDispatcher()
    ) {
        self.healthKitPermissionsController = healthKitPermissionsController
        self.locationPermissionsController = locationPermissionsController
        self.asyncDispatcher = asyncDispatcher
    }

    func didAppear() {
        chatDelegate?.chatControllerIsReady(self)
    }

    // MARK: - ChatController

    func executeNode(_ node: ChatNode) {
        currentNode = node

        if let messagesNode = node as? MessagesNode {
            executeMessagesNode(messagesNode)
        } else if let confirmationNode = node as? UserConfirmationNode {
            executeUserConfirmationNode(confirmationNode)
        } else if let permissionsNode = node as? UserPermissionsNode {
            executeUserPermissionsNode(permissionsNode)
        }
    }

    private func finishExecutionForCurrentNode() {
        if let node = currentNode, node.canContinue {
            completedNodes.append(node)
            currentNode = nil
            updateHighlights()
            chatDelegate?.chatController(self, didFinishExecutingNode: node)
        }
    }

    // MARK: Messages Node Execution

    private func executeMessagesNode(_ node: MessagesNode) {
        insert(messages: node.messages)
    }

    private func didFinishInsertingAllMessages() {
        if var messagesNode = currentNode as? MessagesNode {
            messagesNode.didDeliverAllMessages()
            currentNode = messagesNode
            finishExecutionForCurrentNode()
        }
    }

    // MARK: User Confirmation Node Execution

    private func executeUserConfirmationNode(_ node: UserConfirmationNode) {
        _callToActionText.value = node.callToActionText
    }

    func didReceiveUserConfirmation() {
        if var confirmationNode = currentNode as? UserConfirmationNode {
            _callToActionText.value = nil
            confirmationNode.didReceiveConfirmation()
            currentNode = confirmationNode
            finishExecutionForCurrentNode()
        }
    }

    // MARK: Permissions Request Node Execution

    private func executeUserPermissionsNode(_ node: UserPermissionsNode) {
        let permissionsController: PermissionRequestController

        switch node.permissionsType {
        case .healthKit:
            permissionsController = healthKitPermissionsController
        case .location:
            permissionsController = locationPermissionsController
        }

        let timeNeededToReadPreviousMessage = messageViewModels.first?.readingTime ?? 0
        let additionalPause = 0.2
        let delay = timeNeededToReadPreviousMessage + additionalPause

        asyncDispatcher.after(delay) {
            permissionsController.requestPermissions(completion: { [weak self] in
                Main {
                    self?.didFinishPermissionsRequest()
                }
            })
        }
    }

    private func didFinishPermissionsRequest() {
        guard var mutableNode = currentNode as? UserPermissionsNode else {
            return
        }
        mutableNode.hasAskedForPermissions = true
        currentNode = mutableNode
        finishExecutionForCurrentNode()
    }

    // MARK: - Insertion Flow

    private func beginNextInsertion() {
        guard let nextMessage = pendingMessages.first else {
            didFinishInsertingAllMessages()
            return
        }

        beginTyping(message: nextMessage)
    }

    private func beginTyping(message: Message) {
        let timeNeededToReadPreviousMessage: TimeInterval
        var simulatedPause: TimeInterval = 0.0
        if message.sender == .user {
            // This message is a user response, so we assume that the user has already read the previous message
            timeNeededToReadPreviousMessage = 0.0
        } else {
            timeNeededToReadPreviousMessage = messageViewModels.first?.readingTime ?? 0
            if let previousSender = messageViewModels.first?.message.sender, previousSender == .user {
                // Add a small pause, since we are replying to a user's action
                simulatedPause = 0.2
            }
        }

        let typingDelay = max(timeNeededToReadPreviousMessage + simulatedPause, minimumTypingTime)
        let messageViewModel = ChatMessageViewModel(message: message, animationState: .typing)
        updateHighlight(for: messageViewModel)

        pendingMessages.removeFirst()
        messageViewModels.insert(messageViewModel, at: 0)
        _state.value = .inserting(messageViewModel: messageViewModel)

        asyncDispatcher.after(typingDelay, op: self.beginSlidingCurrentInsertion)
    }

    private func beginSlidingCurrentInsertion() {
        switch _state.value {
        case .inserting(let messageViewModel):
            messageViewModel.animationState = .sliding
            _state.value = .inserting(messageViewModel: messageViewModel)
            asyncDispatcher.after(slidingTime, op: self.beginExpandingCurrentInsertion)
        default:
            break
        }
    }

    private func beginExpandingCurrentInsertion() {
        switch _state.value {
        case .inserting(let messageViewModel):
            messageViewModel.animationState = .expanding
            _state.value = .inserting(messageViewModel: messageViewModel)
            asyncDispatcher.after(expansionTime, op: self.finishInsertion)
        default:
            break
        }
    }

    private func finishInsertion() {
        switch _state.value {
        case .inserting(let messageViewModel):
            messageViewModel.animationState = .idle
        default:
            break
        }
        _state.value = .idle
        beginNextInsertion()
    }

    private var minimumTypingTime: TimeInterval = 0.2
    private var slidingTime: TimeInterval = 0.2
    private var expansionTime: TimeInterval = 0.2

    // MARK: - Message Highlighting

    private func updateHighlight(for messageViewModel: ChatMessageViewModel) {
        guard let condition = messageViewModel.message.highlightCondition else {
            return
        }
        let highlighted: Bool
        switch condition {
        case .always:
            highlighted = true
        case .untilAfter(let nodeIdentifier):
            highlighted = !completedNodes.contains { $0.identifier == nodeIdentifier }
        }
        messageViewModel.isHighlighted = highlighted
    }

    private func updateHighlights() {
        var indexPathsToUpdate = [IndexPath]()
        for (index, item) in tableItems.enumerated() {
            switch item {
            case .message(let messageViewModel):
                if let messageViewModel = messageViewModel as? ChatMessageViewModel {
                    let oldValue = messageViewModel.isHighlighted
                    updateHighlight(for: messageViewModel)
                    if oldValue != messageViewModel.isHighlighted {
                        indexPathsToUpdate.append(IndexPath(row: index, section: 0))
                    }
                }
            default:
                break
            }
        }
        _state.value = .updatingHighlights(indexPaths: indexPathsToUpdate)
        _state.value = .idle
    }
}
