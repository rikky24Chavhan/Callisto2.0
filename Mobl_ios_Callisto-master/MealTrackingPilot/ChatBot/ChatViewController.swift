//
//  ChatViewController.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/17/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import RxSwift

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private struct Constants {
        static let tableTopInset: CGFloat = 20.0
        static let minimumTableBottomInset: CGFloat = 100.0
        static let estimatedScrollDuration: TimeInterval = 0.3
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var confirmationButton: UIButton!
    @IBOutlet weak var backgroundGradientView: GradientView!
    @IBOutlet weak var fadeOverlayView: GradientView!

    private var viewModel: ChatViewModel
    private var chatDriver: ChatDriver
    private let bag = DisposeBag()

    private(set) var state: ChatTableState = .idle

    init(viewModel: ChatViewModel, chatDriver: ChatDriver, nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil) {
        self.viewModel = viewModel
        self.chatDriver = chatDriver
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()
        setupBackgroundGradient()
        setupConfirmationButton()
        setupTopTableFade()
        configureTableView()

        viewModel.state.subscribe(onNext: { [weak self] state in
            self?.updateTable(forState: state)
        }) >>> bag
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.didAppear()
    }

    // MARK: - Navigation Item

    private func setupNavigationItem() {
        navigationItem.hidesBackButton = true
    }

    // MARK: - Background View

    private func setupBackgroundGradient() {
        let colors = [
            UIColor.piCornflower,
            UIColor.piCornflowerTwo,
            UIColor.piSkyBlue,
        ]
        for gradientView in [backgroundGradientView, fadeOverlayView] {
            gradientView?.direction = .vertical
            gradientView?.colors = colors
        }
    }

    private func setupTopTableFade() {
        let colors = [UIColor.white, UIColor.clear]

        let gradientView = GradientView(colors: colors, direction: .vertical)
        gradientView.backgroundColor = UIColor.clear

        let fadeDistance: CGFloat = 32.0
        var frame = view.bounds
        frame.size.height = fadeDistance
        gradientView.frame = frame

        fadeOverlayView.mask = gradientView
    }

    // MARK: - Message Table

    private func configureTableView() {
        ChatMessageTableViewCell.registerNib(tableView)
        SpacerCell.registerCell(tableView)

        tableView.dataSource = self
        tableView.delegate = self

        tableView.tableFooterView = UIView(frame: .zero)

        tableView.contentInset = UIEdgeInsets(
            top: Constants.tableTopInset,
            left: 0,
            bottom: Constants.minimumTableBottomInset,
            right: 0
        )
    }

    private func updateTable(forState state: ChatTableState) {
        if isNearBottomOfTable() {
            updateTableWithAnimation(forState: state)
        } else {
            updateTableWithoutAnimation()
        }
    }

    private func isNearBottomOfTable() -> Bool {
        let offsetThreshold = Constants.minimumTableBottomInset
        return tableView.contentOffset.y < offsetThreshold
    }

    private func updateTableWithAnimation(forState state: ChatTableState) {
        switch state {
        case .inserting(let messageViewModel):
            switch messageViewModel.animationState {
            case .typing:
                tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            case .sliding:
                tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
            case .expanding:
                tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
            default:
                break
            }
        case .updatingHighlights(let indexPaths):
            updateIndexPaths(indexPaths)
        default:
            break
        }
    }

    private func updateTableWithoutAnimation() {
        let contentHeightBefore = tableView.contentSize.height
        let contentOffsetBefore = tableView.contentOffset

        tableView.reloadData()
        view.layoutIfNeeded()

        let contentHeightAfter = tableView.contentSize.height
        let difference = contentHeightAfter - contentHeightBefore

        var contentOffset = contentOffsetBefore
        contentOffset.y += difference
        tableView.contentOffset = contentOffset

        view.layoutIfNeeded()
    }

    private func updateIndexPaths(_ indexPaths: [IndexPath], animated: Bool = true) {
        tableView.beginUpdates()
        tableView.reloadRows(at: indexPaths, with: animated ? .fade : .none)
        tableView.endUpdates()
    }

    private func scrollToBottom(completion: (() -> Void)? = nil) {
        let needsScroll = (tableView.contentOffset.y != 0.0)
        if needsScroll {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            After(Constants.estimatedScrollDuration) {
                completion?()
            }
        } else {
            completion?()
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.tableItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableItem = viewModel.tableItems[indexPath.row]
        switch tableItem {
        case .spacer:
            let cell = tableView.dequeueReusableCell(withIdentifier: SpacerCell.cellIdentifier, for: indexPath)
            cell.backgroundColor = UIColor.clear
            return cell
        case .message(let messageViewModel):
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatMessageTableViewCell.cellIdentifier, for: indexPath)
            if let messageCell = cell as? ChatMessageTableViewCell {
                messageCell.viewModel = messageViewModel
            }
            return cell
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let messageCell = cell as? ChatMessageTableViewCell {
            messageCell.willDisplay()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let tableItem = viewModel.tableItems[indexPath.row]

        switch tableItem {
        case .message(let messageViewModel):
            if let cachedHeight = messageViewModel.cachedCellHight() {
                return cachedHeight
            }
            let sizingCell = ChatMessageTableViewCell.createSizingCell()
            let height = sizingCell.heightThatFits(width: tableView.bounds.width, with: messageViewModel)
            messageViewModel.setCachedCellHeight(height)
            return height
        default:
            return SpacerCell.fixedHeight
        }
    }

    // MARK: - Confirmation Button

    private func setupConfirmationButton() {
        // Hide the button by default
        confirmationButton.alpha = 0.0
        viewModel.callToActionText.subscribe(onNext: self.updateConfirmationButtonWithText(_:)) >>> bag
    }

    private func updateConfirmationButtonWithText(_ text: String?) {
        let textLength = text?.count ?? 0
        let alpha: CGFloat = textLength > 0 ? 1.0 : 0.0

        UIView.animate(withDuration: 0.2) {
            self.confirmationButton.setTitle(text, for: .normal)
            self.confirmationButton.alpha = alpha
        }
    }

    @IBAction func confirmationButtonPressed(_ sender: UIButton) {
        updateConfirmationButtonWithText(nil)
        scrollToBottom(completion: {
            self.viewModel.didReceiveUserConfirmation()
        })
    }

    // MARK: - Outro animation

    private struct OutroAnimationConstants {
        static let tableFadeOutDuration: TimeInterval = 0.5
        static let tableSlidePercentage: CGFloat = 0.25
        static let fadeOutDelay: TimeInterval = 0.2
        static let fadeOutDuration: TimeInterval = 0.5
    }

    func totalOutroAnimationDuration() -> TimeInterval {
        return OutroAnimationConstants.fadeOutDelay + OutroAnimationConstants.fadeOutDuration
    }

    func performOutroAnimation(completion: ((Bool) -> Void)? = nil) {
        var tableDestinationFrame = tableView.frame
        tableDestinationFrame.origin.y -= view.bounds.height * OutroAnimationConstants.tableSlidePercentage

        UIView.animate(withDuration: OutroAnimationConstants.tableFadeOutDuration, animations: {
            self.tableView.frame = tableDestinationFrame
            self.tableView.alpha = 0
        }, completion: nil)

        UIView.animate(
            withDuration: OutroAnimationConstants.fadeOutDuration,
            delay: OutroAnimationConstants.fadeOutDelay,
            options: [],
            animations: {
                self.view.alpha = 0
            },
            completion: completion
        )
    }
}

fileprivate class SpacerCell: UITableViewCell {
    class var fixedHeight: CGFloat {
        return 56
    }
}

fileprivate extension ChatTableState {
    var animationState: ChatMessageAnimationState? {
        switch self {
        case .inserting(let vm):
            return vm.animationState
        default:
            return nil
        }
    }
}
