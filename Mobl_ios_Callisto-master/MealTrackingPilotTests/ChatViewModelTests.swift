//
//  ChatViewModelTests.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/25/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import RxSwift
@testable import MealTrackingPilot

class ChatViewModelTests: XCTestCase {
    private let mockHealthKitController = MockPermissionsRequestController()
    private let mockLocationController = MockPermissionsRequestController()
    private let mockAsyncDispatcher = MockAsyncDispatcher()

    private var chatDriver: ChatDriver?

    lazy var sut: ChatViewModel = ChatViewModel(
        healthKitPermissionsController: self.mockHealthKitController,
        locationPermissionsController: self.mockLocationController,
        asyncDispatcher: self.mockAsyncDispatcher
    )

    var observedTableStates = [ChatTableState]()
    var observedAnimationStates = [ChatMessageAnimationState?]()
    var observedTableItems = [[ChatTableItem]]()
    let bag = DisposeBag()

    override func setUp() {
        super.setUp()

        sut.state.subscribe(onNext: { [weak self] state in
            guard let welf = self else {
                return
            }
            welf.observedTableStates.append(state)
            welf.observedAnimationStates.append(state.viewModelBeingInserted()?.animationState)
            welf.observedTableItems.append(welf.sut.tableItems)
        }) >>> bag
    }

    func testInit() {
        XCTAssert(observedTableStates.last?.isIdle() ?? false, "Should have idle table state")
        XCTAssert(sut.tableItems.count == 1, "Should initialize with 1 item")
        XCTAssert(sut.tableItems.first?.isSpacer() ?? false, "Should contain spacer item.")
    }

    func testInsertion() {
        mockAsyncDispatcher.runSynchronously = true

        let testMessages = [
            Message(text: "Hello world!", sender: .guru),
            Message(text: "So long and thanks for all the fish.", sender: .guru)
        ]

        let messageVM0 = ChatMessageViewModel(message: testMessages[0])
        let messageVM1 = ChatMessageViewModel(message: testMessages[1])

        let expectedTableItems: [[ChatTableItem]] = [
            [ .spacer ],
            [ .message(viewModel: ChatMessageViewModel(message: testMessages[0])) ],
            [ .spacer, .message(viewModel: ChatMessageViewModel(message: testMessages[0])) ],
            [ .spacer, .message(viewModel: ChatMessageViewModel(message: testMessages[0])) ],
            [ .spacer, .message(viewModel: ChatMessageViewModel(message: testMessages[0])) ],
            [ .message(viewModel: ChatMessageViewModel(message: testMessages[1])), .message(viewModel: ChatMessageViewModel(message: testMessages[0])) ],
            [ .spacer, .message(viewModel: ChatMessageViewModel(message: testMessages[1])), .message(viewModel: ChatMessageViewModel(message: testMessages[0])) ],
            [ .spacer, .message(viewModel: ChatMessageViewModel(message: testMessages[1])), .message(viewModel: ChatMessageViewModel(message: testMessages[0])) ],
            [ .spacer, .message(viewModel: ChatMessageViewModel(message: testMessages[1])), .message(viewModel: ChatMessageViewModel(message: testMessages[0])) ],
        ]

        sut.insert(messages: testMessages)

        guard observedTableStates.count == 9 else {
            XCTFail("Should observe 9 table states")
            return
        }

        XCTAssertEqual(observedTableStates[0], .idle)
        XCTAssertEqual(observedTableStates[1], .inserting(messageViewModel: messageVM0))
        XCTAssertEqual(observedTableStates[2], .inserting(messageViewModel: messageVM0))
        XCTAssertEqual(observedTableStates[3], .inserting(messageViewModel: messageVM0))
        XCTAssertEqual(observedTableStates[4], .idle)
        XCTAssertEqual(observedTableStates[5], .inserting(messageViewModel: messageVM1))
        XCTAssertEqual(observedTableStates[6], .inserting(messageViewModel: messageVM1))
        XCTAssertEqual(observedTableStates[7], .inserting(messageViewModel: messageVM1))
        XCTAssertEqual(observedTableStates[8], .idle)

        guard observedAnimationStates.count == 9 else {
            XCTFail("Should observe 9 animation states")
            return
        }

        XCTAssertNil(observedAnimationStates[0])
        XCTAssertNotNilAndEqual(observedAnimationStates[1], .typing)
        XCTAssertNotNilAndEqual(observedAnimationStates[2], .sliding)
        XCTAssertNotNilAndEqual(observedAnimationStates[3], .expanding)
        XCTAssertNil(observedAnimationStates[4])
        XCTAssertNotNilAndEqual(observedAnimationStates[5], .typing)
        XCTAssertNotNilAndEqual(observedAnimationStates[6], .sliding)
        XCTAssertNotNilAndEqual(observedAnimationStates[7], .expanding)
        XCTAssertNil(observedAnimationStates[8])

        guard observedTableItems.count == 9 else {
            XCTFail("Should observe 9 sets of table items")
            return
        }

        XCTAssertEqual(observedTableItems[0], expectedTableItems[0])
        XCTAssertEqual(observedTableItems[1], expectedTableItems[1])
        XCTAssertEqual(observedTableItems[2], expectedTableItems[2])
        XCTAssertEqual(observedTableItems[3], expectedTableItems[3])
        XCTAssertEqual(observedTableItems[4], expectedTableItems[4])
        XCTAssertEqual(observedTableItems[5], expectedTableItems[5])
        XCTAssertEqual(observedTableItems[6], expectedTableItems[6])
        XCTAssertEqual(observedTableItems[7], expectedTableItems[7])
        XCTAssertEqual(observedTableItems[8], expectedTableItems[8])
    }

    func testFullFlow() {
        let asyncExpectation = expectation(description: "Full chat flow")

        let chatGraph = BasicChatNodeGraph(jsonFileName: "test_chat", bundle: Bundle(for: ChatViewModelTests.self))

        chatDriver = ChatDriver(
            chatController: sut,
            asyncDispatcher: mockAsyncDispatcher,
            nodeGraph: chatGraph,
            completion: {
                asyncExpectation.fulfill()
            }
        )
        sut.chatDelegate = chatDriver

        // Mimick the user tapping the CTAs
        sut.callToActionText.subscribe(onNext: { [weak self] text in
            if text != nil {
                DispatchQueue.main.async {
                    self?.sut.didReceiveUserConfirmation()
                }
            }
        }) >>> bag

        sut.didAppear()

        waitForExpectations(timeout: 1.0) { [weak self] error in
            XCTAssertNil(error)

            guard let welf = self else { return }

            let observedTableStates = welf.observedTableStates

            //XCTAssertEqual(self.observedTableStates.count, 22)

            // Starting state
            XCTAssertEqual(observedTableStates[0], .idle)

            // Inserting guru message 0
            XCTAssertNotNilAndEqual(observedTableStates[1].viewModelBeingInserted()?.message.text, "Guru message 0")
            XCTAssertNotNilAndEqual(observedTableStates[2].viewModelBeingInserted()?.message.text, "Guru message 0")
            XCTAssertNotNilAndEqual(observedTableStates[3].viewModelBeingInserted()?.message.text, "Guru message 0")
            XCTAssertEqual(observedTableStates[4], .idle)

            // Inserting guru message 1
            XCTAssertNotNilAndEqual(observedTableStates[5].viewModelBeingInserted()?.message.text, "Guru message 1")
            XCTAssertNotNilAndEqual(observedTableStates[6].viewModelBeingInserted()?.message.text, "Guru message 1")
            XCTAssertNotNilAndEqual(observedTableStates[7].viewModelBeingInserted()?.message.text, "Guru message 1")
            XCTAssertEqual(observedTableStates[8], .idle)

            // Inserting guru message 2
            XCTAssertNotNilAndEqual(observedTableStates[9].viewModelBeingInserted()?.message.text, "Guru message 2")
            XCTAssertNotNilAndEqual(observedTableStates[10].viewModelBeingInserted()?.message.text, "Guru message 2")
            XCTAssertNotNilAndEqual(observedTableStates[11].viewModelBeingInserted()?.message.text, "Guru message 2")
            XCTAssertEqual(observedTableStates[12], .idle)

            // Updating highlights at end of node
            XCTAssertNotNilAndEqual(observedTableStates[13], .updatingHighlights(indexPaths: []))
            XCTAssertEqual(observedTableStates[14], .idle)

            // Updating highlights at end of node
            XCTAssertNotNilAndEqual(observedTableStates[15], .updatingHighlights(indexPaths: []))
            XCTAssertEqual(observedTableStates[16], .idle)

            // Inserting user message
            XCTAssertNotNilAndEqual(observedTableStates[17].viewModelBeingInserted()?.message.text, "User message")
            XCTAssertNotNilAndEqual(observedTableStates[18].viewModelBeingInserted()?.message.text, "User message")
            XCTAssertNotNilAndEqual(observedTableStates[19].viewModelBeingInserted()?.message.text, "User message")
            XCTAssertEqual(observedTableStates[20], .idle)

            // Updating highlights at end of node
            XCTAssertNotNilAndEqual(observedTableStates[21], .updatingHighlights(indexPaths: []))
            XCTAssertEqual(observedTableStates[22], .idle)

            // Updating highlights at end of node
            let guruMessage1IndexPath = IndexPath(row: 3, section: 0)
            XCTAssertNotNilAndEqual(observedTableStates[23], .updatingHighlights(indexPaths: [guruMessage1IndexPath]))
            XCTAssertEqual(observedTableStates[24], .idle)

            // Updating highlights at end of node
            XCTAssertNotNilAndEqual(observedTableStates[25], .updatingHighlights(indexPaths: []))
            XCTAssertEqual(observedTableStates[26], .idle)
        }
    }
}

public func XCTAssertNotNilAndEqual<T: Equatable>(_ expression1: @autoclosure () -> T?, _ expression2: @autoclosure () -> T?, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    guard let lhs = expression1(), let rhs = expression2() else {
        XCTFail(message, file: file, line: line)
        return
    }
    XCTAssertEqual(lhs, rhs, message, file: file, line: line)
}

// MARK: - Helpers

fileprivate extension ChatTableItem {
    func isSpacer() -> Bool {
        switch self {
        case .spacer:
            return true
        default:
            return false
        }
    }

    func isMessage() -> Bool {
        switch self {
        case .message(_):
            return true
        default:
            return false
        }
    }

    func messageViewModel() -> ChatMessageViewModel? {
        switch self {
        case .message(let viewModel):
            return viewModel as? ChatMessageViewModel
        default:
            return nil
        }
    }
}

extension ChatTableItem: Equatable {
    public static func ==(_ lhs: ChatTableItem, _ rhs: ChatTableItem) -> Bool {
        if lhs.isSpacer() && rhs.isSpacer() {
            return true
        }
        if let lhsVM = lhs.messageViewModel(), let rhsVM = rhs.messageViewModel() {
            return lhsVM == rhsVM
        }
        return false
    }
}

fileprivate extension ChatTableState {
    func isIdle() -> Bool {
        switch self {
        case .idle:
            return true
        default:
            return false
        }
    }

    func isInserting() -> Bool {
        switch self {
        case .inserting(_):
            return true
        default:
            return false
        }
    }

    func viewModelBeingInserted() -> ChatMessageViewModel? {
        switch self {
        case .inserting(let viewModel):
            return viewModel as? ChatMessageViewModel
        default:
            return nil
        }
    }

    func isUpdatingHighlights() -> Bool {
        switch self {
        case .updatingHighlights(_):
            return true
        default:
            return false
        }
    }

    func highlightsBeingUpdated() -> [IndexPath]? {
        switch self {
        case .updatingHighlights(let indexPaths):
            return indexPaths
        default:
            return nil
        }
    }
}

extension ChatTableState: Equatable {
    public static func ==(_ lhs: ChatTableState, _ rhs: ChatTableState) -> Bool {
        if lhs.isIdle() && rhs.isIdle() {
            return true
        }
        if let lhsVM = lhs.viewModelBeingInserted(), let rhsVM = rhs.viewModelBeingInserted() {
            return lhsVM == rhsVM
        }
        if let lhsHighlights = lhs.highlightsBeingUpdated(), let rhsHighlights = rhs.highlightsBeingUpdated() {
            return lhsHighlights == rhsHighlights
        }
        return false
    }
}

// MARK: - Mocks

fileprivate class MockPermissionsRequestController: PermissionRequestController {
    var didRequestPermissions = false

    func requestPermissions(completion: @escaping () -> Void) {
        didRequestPermissions = true
        completion()
    }
}

fileprivate class MockAsyncDispatcher: AsyncDispatcherProtocol {
    var runSynchronously: Bool = false

    func after(_ delay: TimeInterval, op: @escaping () -> Void) {
        if runSynchronously {
            op()
        } else {
            DispatchQueue.main.async(execute: op)
        }
    }
}
