//
//  DashboardViewController.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/7/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import KeychainAccess
import RxSwift
import RxCocoa
import Intrepid

fileprivate final class ScrollInteraction {

    private enum State {
        case start, interacting, finished
    }
    private var currentState = State.start

    let minScrollProgress: CGFloat
    let maxScrollProgress: CGFloat

    let interaction: (_ scrollProgress: CGFloat, _ interactionProgress: CGFloat) -> Void
    var defaultState: (() -> Void)?
    var finishedState: (() -> Void)?

    init(minScrollProgress: CGFloat = 0, maxScrollProgress: CGFloat = 1, interaction: @escaping (_ scrollProgress: CGFloat, _ interactionProgress: CGFloat) -> Void) {
        self.minScrollProgress = minScrollProgress
        self.maxScrollProgress = maxScrollProgress
        self.interaction = interaction
    }

    func update(scrollProgress: CGFloat) {
        guard
            scrollProgress >= minScrollProgress,
            scrollProgress <= maxScrollProgress
            else {
                if currentState != .start,
                    scrollProgress <= minScrollProgress {
                    currentState = .start
                    defaultState?()
                } else if currentState != .finished,
                    scrollProgress >= maxScrollProgress {
                    currentState = .finished
                    finishedState?()
                }

                return
        }

        currentState = .interacting

        let interactionProgress = normalize(min: minScrollProgress, max: maxScrollProgress, current: scrollProgress)
        interaction(scrollProgress, interactionProgress)
    }
}

private var isIphoneX: Bool {
    return UIScreen.main.bounds.height > 736
}

final class DashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DashboardTableViewCellDelegate {

    // MARK: - Properties

    private struct Constants {
        static let title = "Your Meals"
        static let testMealsButtonTitle = "Test Meal"
        static let commonMealsButtonTitle = "Common Meal"
        static let statusBarHeight: CGFloat = 20
        static let dockThreshhold: CGFloat = 1 - 2 / 3

        static let differenceBetweenFullscreenAndVisible: CGFloat = 119

        static let backgroundFadeMinValue: CGFloat = 1 - 2 / 3
        static let backgroundFadeMaxValue: CGFloat = 1 - 1 / 4

        static let mealButtonCornerRadius: CGFloat = 12.0
        static let mealButtonBottomThreshold: CGFloat = 1 / 2
        static let mealButtonTopThreshold: CGFloat = 1
        static let mealButtonUndockedHeight: CGFloat = 54
        static let mealButtonDockedVerticalPadding: CGFloat = 20
        static let mealButtonUndockedVerticalPadding: CGFloat = 16
        static let mealButtonContainerUndockedTopConstant: CGFloat = 92

        static let homeButtonScrollStartThreshold: CGFloat = 1 / 3

        static let heightOfPeakedTableView: CGFloat = isIphoneX ? 104 : 72

        static let homeButtonUndockedTopConstant: CGFloat = isIphoneX || UIDevice.current.isRunningiOS10 ? 55 : 36
        static let homeButtonFullscreenTopConstant: CGFloat = isIphoneX ? 45 : 23

        static let statusBarImageContextHeight: CGFloat = isIphoneX ? 50 : 20

        static let tableViewContainerTopSpace: CGFloat = UIDevice.current.isRunningiOS10 ? 45 : 23

        static let endOfListViewHeight: CGFloat = 64
        static let defaultCopyrightCellHeight: CGFloat = 134
        static let dateHeaderHeight: CGFloat = 46
        static let mealCellHeight: CGFloat = 160
        static let mealSectionSeparatorHeight: CGFloat = 23
        static let mealSeparatorHeight: CGFloat = 4
    }

    private let viewModel: DashboardViewModel
    private let bag = DisposeBag()

    @IBOutlet private weak var tableView: DashboardTableView!
    @IBOutlet private weak var welcomeView: DashboardHomeHeaderView!
    @IBOutlet private weak var welcomeViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var dockedBackgroundView: UIView!
    @IBOutlet private weak var undockedBackgroundView: UIView!
    @IBOutlet private weak var tableViewContainerView: RoundedCornerView!
    @IBOutlet private weak var settingsButton: UIButton!
    @IBOutlet private weak var blockingActivityIndicatorView: UIView!
    @IBOutlet private weak var tableViewContainerTopSpaceConstraint: NSLayoutConstraint!

    fileprivate var scrollInteractions: [ScrollInteraction] = []

    private var shadowViewTopConstraint: NSLayoutConstraint!
    private lazy var shadowView: UIView = {
        let shadowView = UIView()
        shadowView.backgroundColor = UIColor.clear
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowRadius = 4
        shadowView.layer.shadowOpacity = 0.5
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        return shadowView
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.piDenim
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.gray, for: .highlighted)
        button.setTitle("I’m done with the demo", for: .normal)
        button.titleLabel?.font = UIFont.openSansBoldFont(size: 16.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 25
        return button
    }()

    private var homeButtonTopConstraint: NSLayoutConstraint!
    private lazy var homeButton: DashboardHomeButton = {
        let button = DashboardHomeButton()
        button.alpha = 0
        button.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        button.addTarget(self, action: #selector(homeButtonTapped(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var testMealButton: GradientButton = {
        let mealButton = GradientButton()
        mealButton.title = Constants.testMealsButtonTitle
        mealButton.gradientColors = [
            UIColor.piTestMealButtonGradientStartColor,
            UIColor.piTestMealButtonGradientFinishColor
        ]
        mealButton.cornerRadius = Constants.mealButtonCornerRadius
        mealButton.addTarget(self, action: #selector(testMealButtonTapped(_:)), for: .touchUpInside)
        mealButton.translatesAutoresizingMaskIntoConstraints = false
        return mealButton
    }()

    private lazy var commonMealButton: GradientButton = {
        let mealButton = GradientButton()
        mealButton.title = Constants.commonMealsButtonTitle
        mealButton.gradientColors = [
            UIColor.piCommonMealGradientStartColor,
            UIColor.piCommonMealGradientFinishColor
        ]
        mealButton.cornerRadius = Constants.mealButtonCornerRadius
        mealButton.addTarget(self, action: #selector(commonMealButtonTapped(_:)), for: .touchUpInside)
        mealButton.translatesAutoresizingMaskIntoConstraints = false
        return mealButton
    }()

    private lazy var mealButtonContainerView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.testMealButton, self.commonMealButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private var mealButtonContainerHeightConstraint: NSLayoutConstraint!
    private var mealButtonContainerVerticalPadding = Constants.mealButtonDockedVerticalPadding
    private var mealButtonContainerTopConstraint: NSLayoutConstraint!

    var invisibleHeaderHeight: CGFloat = 0

    private enum ViewMode {
        case docked
        case visible
        case fullscreen
    }
    private var viewMode: ViewMode = .docked {
        didSet(oldValue) {
            viewModel.mealJournalIsDocked.value = viewMode == .docked
        }
    }

    private var dockedContentOffset: CGFloat = 0
    private var visibleContentOffset: CGFloat = 0
    private var fullscreenContentOffset: CGFloat = 0

    private var statusBarImageView: UIImageView?

    private var mealJournalHeaderTopConstraint: NSLayoutConstraint!
    private lazy var mealJournalHeaderView: DashboardDateHeaderView = {
        let viewModel = MealJournalHeaderViewModel()
        let headerView = DashboardDateHeaderView()
        headerView.viewModel = viewModel
        headerView.isTopHeader = true
        headerView.isUserInteractionEnabled = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()

    var scrollProgressForFullscreen: CGFloat {
        return invisibleHeaderHeight / visibleContentOffset
    }

    fileprivate var footerViewTopConstraint: NSLayoutConstraint!

    fileprivate lazy var endOfListView: UIView = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: Constants.endOfListViewHeight))
        label.backgroundColor = UIColor.piAlmostWhite
        label.text = "- End of List -"
        label.textColor = UIColor.piGreyblue
        label.font = UIFont.openSansItalicFont(size: 16.0)
        label.textAlignment = .center
        return label
    }()

    fileprivate lazy var footerView: UIView = {
        let footerView = UIView()
        footerView.backgroundColor = UIColor.piAlmostWhite
        footerView.translatesAutoresizingMaskIntoConstraints = false
        return footerView
    }()

    fileprivate lazy var emptyView: UIView = {
        let emptyView = UIView()
        emptyView.backgroundColor = UIColor.piPaleGreyTwo
        emptyView.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: #imageLiteral(resourceName: "allIllustrationLarge"))
        emptyView.addSubview(imageView)
        emptyView.constrainView(toTop: imageView, withInset: 40.0)
        emptyView.constrainView(toMiddleHorizontally: imageView)

        let label = UILabel(frame: .zero)
        label.text = "You have not logged any meals yet."
        label.font = UIFont.openSansSemiboldFont(size: 24.0)
        label.textColor = UIColor.piDenim.withAlphaComponent(0.5)
        label.textAlignment = .center
        label.numberOfLines = 2
        emptyView.addSubview(label)
        emptyView.constrainView(label, attribute: .top, to: imageView, attribute: .bottom, constant: 22.0, multiplier: 1.0)
        emptyView.constrainView(toMiddleHorizontally: label)
        label.constrainView(label, toWidth: 272.0)

        let copyrightLabel = UILabel(frame: .zero)
        copyrightLabel.text = "Copyright 2018 © Eli Lilly and Company.\nAll rights reserved."
        copyrightLabel.font = UIFont.openSansFont(size: 12.0)
        copyrightLabel.textColor = UIColor.piGreyblue
        copyrightLabel.textAlignment = .center
        copyrightLabel.numberOfLines = 2
        emptyView.addSubview(copyrightLabel)
        emptyView.constrainView(toBottom: copyrightLabel, withInset: -10.0)
        emptyView.constrainView(toMiddleHorizontally: copyrightLabel)
        copyrightLabel.constrainView(copyrightLabel, toWidth: 223.0)

        return emptyView
    }()

    // MARK: - Lifecycle

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel

        super.init(nibName: DashboardViewController.ip_nibName, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        getData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: animated)
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        var roundedRect = shadowView.bounds.insetBy(dx: 0, dy: 0)
        roundedRect.origin.y += 5
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: roundedRect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 12, height: 12)).cgPath
    }

    override func viewDidLayoutSubviews() {
        updateScrollState()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        guard let tableView = tableView else {
            return .lightContent
        }

        let scrollProgress = tableView.contentOffset.y / visibleContentOffset
        if scrollProgress <= 0 {
            return .lightContent
        }

        return .default
    }

    // MARK: - Actions

    @IBAction private func settingsButtonPressed(_ sender: UIButton) {
        displaySettings()
    }

    @objc private func commonMealButtonTapped(_ sender: UIButton) {
        presentLogMealEventViewController(mealClassification: .common)
    }

    @objc private func testMealButtonTapped(_ sender: UIButton) {
        presentLogMealEventViewController(mealClassification: .test)
    }

    @objc func homeButtonTapped(_ sender: DashboardHomeButton) {
        viewMode = .docked
        tableView.setContentOffset(CGPoint(x: 0, y: self.dockedContentOffset), animated: true)
    }

    private func presentLogMealEventViewController(mealClassification: MealClassification) {
        let logMealEventViewController = LogMealEventViewController(viewModel: viewModel.logMealEventViewModel(mealClassification: mealClassification))
        let navigationController = UINavigationController(rootViewController: logMealEventViewController)
        present(navigationController, animated: true, completion: nil)
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: Settings

    private func displaySettings() {
        let settingsViewController = SettingsViewController()
        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    // MARK: Setup

    func setup() {
        automaticallyAdjustsScrollViewInsets = false
        navigationController?.setNavigationBarHidden(true, animated: false)
        title = Constants.title

        let screenHeight = UIScreen.main.bounds.height
        invisibleHeaderHeight = screenHeight - Constants.heightOfPeakedTableView - tableViewContainerView.frame.minY
        let invisibleHeader = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: invisibleHeaderHeight))

        invisibleHeader.backgroundColor = .clear
        invisibleHeader.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = invisibleHeader
        invisibleHeader.heightAnchor.constraint(equalToConstant: invisibleHeaderHeight).isActive = true

        dockedContentOffset = 0
        visibleContentOffset = invisibleHeaderHeight - Constants.differenceBetweenFullscreenAndVisible
        fullscreenContentOffset = invisibleHeaderHeight

        setupDockedBackgroundView()
        setupSettingsButton()
        setupMealButtons()
        setupTableView()
        setupTableViewContainerView()
        setupActionButton()
        setupShadowView()
        setupMealJournalHeaderView()
        setupDashboardHomeButton()
        setupScrollInteractions()
        setupFooterView()
        setupEmptyView()
        setupBlockingActivityIndicatorView()
        setupSignificantTimeChangeNotification()

        welcomeView.currentDayText = viewModel.weekdayName
        welcomeView.mealEventCountLabel.rx.attributedText <- viewModel.logMessage >>> bag
        viewModel.suggestionMessage.subscribe(onNext: { [weak self] suggestionMessage in
            self?.welcomeView.suggestionMessage = suggestionMessage
        }) >>> bag
        viewModel.mealJournalIsDocked.value = true
    }

    func setupSettingsButton() {
        settingsButton.isHidden = !viewModel.shouldDisplaySettingsButton
    }

    func setupDockedBackgroundView() {
        let gradientView = GradientView()
        dockedBackgroundView.addSubview(gradientView)

        gradientView.apply(viewModel.backgroundGradientSpec)
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.topAnchor.constraint(equalTo: dockedBackgroundView.topAnchor).isActive = true
        gradientView.bottomAnchor.constraint(equalTo: dockedBackgroundView.bottomAnchor).isActive = true
        gradientView.leadingAnchor.constraint(equalTo: dockedBackgroundView.leadingAnchor).isActive = true
        gradientView.trailingAnchor.constraint(equalTo: dockedBackgroundView.trailingAnchor).isActive = true
    }

    func setupMealButtons() {
        view.insertSubview(mealButtonContainerView, belowSubview: tableViewContainerView)

        mealButtonContainerView.leadingAnchor.constraint(equalTo: tableViewContainerView.leadingAnchor, constant: 8.0).isActive = true
        mealButtonContainerView.trailingAnchor.constraint(equalTo: tableViewContainerView.trailingAnchor, constant: -8.0).isActive = true
        mealButtonContainerTopConstraint = mealButtonContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: invisibleHeaderHeight + tableViewContainerView.frame.minY - viewModel.mealButtonDockedHeight - mealButtonContainerVerticalPadding)
        mealButtonContainerTopConstraint.isActive = true
        mealButtonContainerHeightConstraint = testMealButton.heightAnchor.constraint(equalToConstant: viewModel.mealButtonDockedHeight)
        mealButtonContainerHeightConstraint.isActive = true

        testMealButton.rx.isEnabled <- viewModel.canLogTestMeal >>> bag
        commonMealButton.rx.isEnabled <- viewModel.canLogCommonMeal >>> bag
    }

    func setupTableView() {
        tableView.estimatedRowHeight = DashboardTableViewCell.estimatedHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = DashboardDateTableHeaderView.estimatedHeight
        tableView.sectionHeaderHeight = DashboardDateTableHeaderView.estimatedHeight
        tableView.separatorStyle = .none
        tableView.passThroughViews = [commonMealButton, testMealButton, settingsButton]

        DashboardTableViewCell.registerNib(tableView)
        DashboardDateTableHeaderView.registerHeaderFooterView(tableView)
        tableView.register(CopyrightTableViewCell.ip_nib, forCellReuseIdentifier: CopyrightTableViewCell.ip_identifier)

        viewModel.tableUpdateObservable.subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }) >>> bag
    }

    func setupTableViewContainerView() {
        tableViewContainerView.roundedCorners = [.topLeft, .topRight]
        tableViewContainerTopSpaceConstraint.constant = Constants.tableViewContainerTopSpace
    }

    func setupActionButton() {
        view.addSubview(actionButton)

        let device = UIDevice.current
        let verticalSpacing: CGFloat = device.isSmall ? 16 : 20

        actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        actionButton.topAnchor.constraint(equalTo: welcomeView.bottomAnchor, constant: verticalSpacing).isActive = true
        actionButton.widthAnchor.constraint(equalToConstant: 264).isActive = true
        actionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        actionButton.rx.isHidden <- viewModel.shouldDisplayActionButton.map({ !$0 }) >>> bag
        actionButton.rx.tap.single().subscribe(onNext: { [weak self] in
            self?.viewModel.action?()
        }) >>> bag
    }

    func setupDashboardHomeButton() {
        view.addSubview(homeButton)

        homeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        homeButtonTopConstraint = homeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.homeButtonUndockedTopConstant)
        homeButtonTopConstraint.isActive = true
        homeButton.widthAnchor.constraint(equalToConstant: 43).isActive = true
        homeButton.heightAnchor.constraint(equalTo: homeButton.widthAnchor).isActive = true

        homeButton.gradientDirection = viewModel.homeButtonGradientDirection
        homeButton.normalBackgroundColors = viewModel.homeButtonNormalBackgroundColors
        homeButton.highlightedBackgroundColors = viewModel.homeButtonHighlightedBackgroundColors
    }

    func setupShadowView() {
        view.insertSubview(shadowView, belowSubview: tableViewContainerView)

        shadowView.leadingAnchor.constraint(equalTo: tableViewContainerView.leadingAnchor).isActive = true
        shadowView.trailingAnchor.constraint(equalTo: tableViewContainerView.trailingAnchor).isActive = true
        shadowViewTopConstraint = shadowView.topAnchor.constraint(equalTo: tableViewContainerView.topAnchor, constant: invisibleHeaderHeight)
        shadowViewTopConstraint.isActive = true
        shadowView.heightAnchor.constraint(equalTo: tableViewContainerView.heightAnchor).isActive = true
    }

    func setupMealJournalHeaderView() {
        view.addSubview(mealJournalHeaderView)

        mealJournalHeaderView.leadingAnchor.constraint(equalTo: tableViewContainerView.leadingAnchor).isActive = true
        mealJournalHeaderView.trailingAnchor.constraint(equalTo: tableViewContainerView.trailingAnchor).isActive = true
        mealJournalHeaderTopConstraint = mealJournalHeaderView.topAnchor.constraint(equalTo: tableViewContainerView.topAnchor, constant: invisibleHeaderHeight)
        mealJournalHeaderTopConstraint.isActive = true
    }

    func setupScrollInteractions() {
        defer {
            // Has to be the last interaction because some variables may change from other scroll interactions
            let onScrollScrollInteraction = ScrollInteraction(minScrollProgress: 0, maxScrollProgress: 1) { [weak self] scrollProgress, interactionProgress in
                guard let welf = self else { return }

                welf.welcomeViewTopConstraint.constant = welf.viewModel.initialWelcomeViewTopConstant - welf.tableView.contentOffset.y
                welf.mealButtonContainerTopConstraint.constant = welf.invisibleHeaderHeight + welf.tableViewContainerView.frame.minY - welf.mealButtonContainerHeightConstraint.constant - welf.mealButtonContainerVerticalPadding - welf.tableView.contentOffset.y
                welf.interactivelyUpdateStatusBarColor(interactionProgress: interactionProgress)
            }

            onScrollScrollInteraction.defaultState = { [weak self] in
                guard let welf = self else { return }

                welf.welcomeViewTopConstraint.constant = welf.viewModel.initialWelcomeViewTopConstant
                welf.mealButtonContainerTopConstraint.constant = welf.invisibleHeaderHeight + welf.tableViewContainerView.frame.minY - welf.viewModel.mealButtonDockedHeight - welf.mealButtonContainerVerticalPadding
                welf.interactivelyUpdateStatusBarColor(interactionProgress: 0)
            }

            onScrollScrollInteraction.finishedState = { [weak self] in
                guard let welf = self else { return }

                welf.welcomeViewTopConstraint.constant = welf.viewModel.initialWelcomeViewTopConstant - welf.tableView.contentOffset.y
                welf.mealButtonContainerTopConstraint.constant = Constants.mealButtonContainerUndockedTopConstant
                welf.interactivelyUpdateStatusBarColor(interactionProgress: 1)
            }

            scrollInteractions.append(onScrollScrollInteraction)
        }

        let backgroundScrollInteraction = ScrollInteraction(minScrollProgress: Constants.backgroundFadeMinValue, maxScrollProgress: Constants.backgroundFadeMaxValue) { [weak self] scrollProgress, interactionProgress in
            guard let welf = self else { return }

            let progress = 1 - interactionProgress

            welf.dockedBackgroundView.alpha = progress
            welf.settingsButton.tintColor = UIColor.color(
                from: .piWhite,
                to: .piDenim,
                progress: progress
            )
        }

        backgroundScrollInteraction.defaultState = { [weak self] in
            guard let welf = self else { return }
            welf.dockedBackgroundView.alpha = 1
            welf.settingsButton.tintColor = .piWhite
        }

        backgroundScrollInteraction.finishedState = { [weak self] in
            guard let welf = self else { return }
            welf.dockedBackgroundView.alpha = 0
            welf.settingsButton.tintColor = .piDenim
        }
        scrollInteractions.append(backgroundScrollInteraction)

        let headerScrollInteraction = ScrollInteraction(maxScrollProgress: Constants.dockThreshhold) { [weak self] scrollProgress, interactionProgress in
            guard let welf = self else { return }

            welf.welcomeView.alpha = 1 - interactionProgress
            welf.actionButton.alpha = 1 - interactionProgress
            welf.mealJournalHeaderView.contentAlpha = 1 - (welf.viewModel.mealJournalIsEmpty.value ? 0 : interactionProgress)
            welf.mealJournalHeaderView.alpha = 1 - (welf.viewModel.mealJournalIsEmpty.value ? 0 : interactionProgress)
            welf.mealJournalHeaderView.dateLabel.alpha = 1 - interactionProgress
        }

        headerScrollInteraction.defaultState = { [weak self] in
            guard let welf = self else { return }
            welf.welcomeView.alpha = 1
            welf.actionButton.alpha = 1
            welf.mealJournalHeaderView.contentAlpha = 1
            welf.mealJournalHeaderView.alpha = 1
            welf.mealJournalHeaderView.dateLabel.alpha = 1
        }

        headerScrollInteraction.finishedState = { [weak self] in
            guard let welf = self else { return }
            welf.welcomeView.alpha = 0
            welf.actionButton.alpha = 0
            welf.mealJournalHeaderView.contentAlpha = welf.viewModel.mealJournalIsEmpty.value ? 1 : 0
            welf.mealJournalHeaderView.alpha = welf.viewModel.mealJournalIsEmpty.value ? 1 : 0
            welf.mealJournalHeaderView.dateLabel.alpha = 0
        }
        scrollInteractions.append(headerScrollInteraction)

        let homeButtonScrollInteraction = ScrollInteraction(minScrollProgress: Constants.homeButtonScrollStartThreshold) { [weak self] scrollProgress, interactionProgress in
            guard let welf = self else { return }
            let scale = 1.5 - 0.5 * interactionProgress

            welf.homeButton.alpha = interactionProgress
            welf.homeButton.transform = CGAffineTransform(scaleX: scale, y: scale)
        }

        homeButtonScrollInteraction.defaultState = { [weak self] in
            guard let welf = self else { return }
            welf.homeButton.alpha = 0
            welf.homeButton.transform = .identity
        }

        homeButtonScrollInteraction.finishedState = { [weak self] in
            guard let welf = self else { return }
            welf.homeButton.alpha = 1
            welf.homeButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        scrollInteractions.append(homeButtonScrollInteraction)

        let mealButtonContainerScrollInteraction = ScrollInteraction(minScrollProgress: Constants.mealButtonBottomThreshold, maxScrollProgress: Constants.mealButtonTopThreshold) { [weak self] scrollProgress, interactionProgress in
            guard let welf = self else { return }

            let buttonHeight = welf.viewModel.mealButtonDockedHeight - ((welf.viewModel.mealButtonDockedHeight - Constants.mealButtonUndockedHeight) * interactionProgress)
            welf.mealButtonContainerHeightConstraint.constant = buttonHeight

            welf.mealButtonContainerVerticalPadding = Constants.mealButtonDockedVerticalPadding - ((Constants.mealButtonDockedVerticalPadding - Constants.mealButtonUndockedVerticalPadding) * interactionProgress)
        }

        mealButtonContainerScrollInteraction.defaultState = { [weak self] in
            guard let welf = self else { return }
            welf.mealButtonContainerHeightConstraint.constant = welf.viewModel.mealButtonDockedHeight
            welf.mealButtonContainerVerticalPadding = Constants.mealButtonDockedVerticalPadding
        }

        mealButtonContainerScrollInteraction.finishedState = { [weak self] in
            guard let welf = self else { return }
            welf.mealButtonContainerHeightConstraint.constant = Constants.mealButtonUndockedHeight
            welf.mealButtonContainerVerticalPadding = Constants.mealButtonUndockedVerticalPadding
        }

        scrollInteractions.append(mealButtonContainerScrollInteraction)

        let homeButtonFullscreenScrollInteraction = ScrollInteraction(minScrollProgress: 1, maxScrollProgress: scrollProgressForFullscreen) { [weak self] scrollProgress, interactionProgress in
            guard let welf = self else { return }

            welf.homeButtonTopConstraint.constant = Constants.homeButtonUndockedTopConstant - ((Constants.homeButtonUndockedTopConstant - Constants.homeButtonFullscreenTopConstant) * interactionProgress)
            welf.homeButton.chevronAlpha = interactionProgress
        }

        homeButtonFullscreenScrollInteraction.defaultState = { [weak self] in
            guard let welf = self else { return }
            welf.homeButton.chevronAlpha = 0
            welf.homeButtonTopConstraint.constant = Constants.homeButtonUndockedTopConstant
        }

        homeButtonFullscreenScrollInteraction.finishedState = { [weak self] in
            guard let welf = self else { return }
            welf.homeButton.chevronAlpha = 1
            welf.homeButtonTopConstraint.constant = Constants.homeButtonFullscreenTopConstant
        }

        scrollInteractions.append(homeButtonFullscreenScrollInteraction)

        // -1 so it continues to follow the visible part of the table view when scrolling down
        let shadowViewScrollInteraction = ScrollInteraction(minScrollProgress: -1, maxScrollProgress: scrollProgressForFullscreen) { [weak self] scrollProgress, interactionProgress in
            guard let welf = self else { return }

            let y = welf.invisibleHeaderHeight - welf.tableView.contentOffset.y
            welf.shadowViewTopConstraint.constant = y
            welf.mealJournalHeaderTopConstraint.constant = y
        }

        shadowViewScrollInteraction.defaultState = { [weak self] in
            guard let welf = self else { return }

            welf.shadowViewTopConstraint.constant = welf.invisibleHeaderHeight
            welf.mealJournalHeaderTopConstraint.constant = welf.invisibleHeaderHeight
        }

        shadowViewScrollInteraction.finishedState = { [weak self] in
            guard let welf = self else { return }

            welf.shadowViewTopConstraint.constant = 0
            welf.mealJournalHeaderTopConstraint.constant = 0
        }
        scrollInteractions.append(shadowViewScrollInteraction)
    }

    func updateScrollState() {
        let scrollProgress = tableView.contentOffset.y / visibleContentOffset
        scrollInteractions.forEach { $0.update(scrollProgress: scrollProgress) }

        // Have to fake the footer view so that the table view bounces at the end
        let scrollOffset = tableView.contentOffset.y
        let scrollViewHeight = tableView.frame.height
        let scrollViewContentSizeHeight = tableView.contentSize.height

        if scrollOffset + scrollViewHeight >= scrollViewContentSizeHeight {
            let offsetFromBottom = scrollViewContentSizeHeight - (scrollOffset + scrollViewHeight)
            footerViewTopConstraint.constant = offsetFromBottom
        } else {
            footerViewTopConstraint.constant = 0
        }
    }

    func interactivelyUpdateStatusBarColor(interactionProgress: CGFloat) {
        guard let statusBarWindow = UIApplication.shared.value(forKey: "statusBarWindow") as? UIWindow else { return }

        if interactionProgress == 0 || interactionProgress == 1 {
            setNeedsStatusBarAppearanceUpdate()
            statusBarImageView?.removeFromSuperview()
            statusBarImageView = nil
            statusBarWindow.alpha = 1
            return
        }

        if let statusBarImageView = statusBarImageView {
            statusBarImageView.tintColor = UIColor.color(
                from: UIColor(red: 1, green: 1, blue: 1, alpha: 1),
                to: UIColor(red: 0, green: 0, blue: 0, alpha: 1),
                progress: 1 - interactionProgress
            )
        } else {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: statusBarWindow.bounds.width, height: Constants.statusBarImageContextHeight), false, statusBarWindow.screen.scale)
            statusBarWindow.layer.render(in: UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            let imageView = UIImageView(image: image?.withRenderingMode(.alwaysTemplate))
            imageView.tintColor = UIColor.white
            imageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(imageView)

            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: Constants.statusBarImageContextHeight).isActive = true

            statusBarImageView = imageView

            statusBarWindow.alpha = 0
        }
    }

    func setupFooterView() {
        tableViewContainerView.insertSubview(footerView, belowSubview: tableView)

        footerView.leadingAnchor.constraint(equalTo: tableViewContainerView.leadingAnchor).isActive = true
        footerView.trailingAnchor.constraint(equalTo: tableViewContainerView.trailingAnchor).isActive = true
        footerView.heightAnchor.constraint(equalTo: tableViewContainerView.heightAnchor).isActive = true
        footerViewTopConstraint = footerView.topAnchor.constraint(equalTo: tableViewContainerView.bottomAnchor)
        footerViewTopConstraint.isActive = true

        footerView.rx.alpha <- viewModel.footerViewAlpha >>> bag
    }

    func setupEmptyView() {
        tableViewContainerView.insertSubview(emptyView, aboveSubview: footerView)
        tableViewContainerView.constrainView(emptyView, attribute: .top, to: footerView, attribute: .top, constant: 40.0, multiplier: 1.0, relation: .equal)
        tableViewContainerView.constrainView(toLeft: emptyView)
        tableViewContainerView.constrainView(toRight: emptyView)
        tableViewContainerView.constrainView(emptyView, toBottomOf: footerView)

        emptyView.rx.alpha <- viewModel.emptyViewAlpha >>> bag
    }

    func setupBlockingActivityIndicatorView() {
        blockingActivityIndicatorView.rx.isHidden <- viewModel.shouldHideBlockingActivityIndicator >>> bag
    }

    func setupSignificantTimeChangeNotification() {
        NotificationCenter.default.addObserver(forName: .UIApplicationSignificantTimeChange, object: nil, queue: nil) { [weak self] _ in
            guard let welf = self else { return }
            welf.welcomeView.currentDayText = welf.viewModel.weekdayName
        }
    }

    // MARK: - Networking

    private func getData() {
        viewModel.getMeals { [weak self] result in
            if let error = result.error {
                Main {
                    self?.displayDataError(error)
                }
            }
        }
    }

    private func displayDataError(_ error: Error) {
        let alert = UIAlertController.errorAlertController(withMessage: "Unable to communicate with the server, some meals may be missing from the meal journal.")
        present(alert, animated: true, completion: nil)
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        let numberOfDates = viewModel.numberOfDatesLogged()
        return numberOfDates > 0 ? numberOfDates + 1 : 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == viewModel.numberOfDatesLogged() ? 1 : viewModel.numberOfMeals(for: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case viewModel.numberOfDatesLogged():
            let cell = tableView.dequeueReusableCell(withIdentifier: CopyrightTableViewCell.ip_identifier, for: indexPath) as! CopyrightTableViewCell

            cell.selectionStyle = .none
            cell.configure(with: endOfListView)

            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: DashboardTableViewCell.cellIdentifier, for: indexPath) as! DashboardTableViewCell

            cell.delegate = self

            if let meal = viewModel.cellViewModel(at: indexPath) {
                cell.configure(with: meal)
            }
            let numberOfMealsInSection = viewModel.numberOfMeals(for: indexPath.section)
            if indexPath.section == viewModel.numberOfDatesLogged() - 1 {
                cell.separatorType = indexPath.row == numberOfMealsInSection - 1 ? .none : .compact
            } else {
                cell.separatorType = indexPath.row == numberOfMealsInSection - 1 ? .extended : .compact
            }

            cell.selectionStyle = .none

            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == viewModel.numberOfDatesLogged() {
            let totalNumberOfMealsLogged = viewModel.numberOfDatesLogged()
            let totalNumberOfDatesLogged = viewModel.numberOfDatesLogged()
            let totalMealCardHeight = Constants.mealCellHeight * CGFloat(totalNumberOfMealsLogged)
            let totalSectionSeparatorHeight = Constants.mealSectionSeparatorHeight * CGFloat(totalNumberOfDatesLogged - 1)
            let totalSeparatorHeight = Constants.mealSeparatorHeight * CGFloat(totalNumberOfMealsLogged - totalNumberOfDatesLogged)
            let mealContentSize = totalMealCardHeight + totalSectionSeparatorHeight + totalSeparatorHeight
            let proposedHeight = tableView.frame.height - mealContentSize - Constants.dateHeaderHeight

            return proposedHeight > Constants.defaultCopyrightCellHeight ? proposedHeight : Constants.defaultCopyrightCellHeight
        } else {
            let isLastDate = indexPath.section == viewModel.numberOfDatesLogged() - 1
            let isLastMealInSection = indexPath.row == viewModel.numberOfMeals(for: indexPath.section) - 1

            if isLastDate && isLastMealInSection {
                return Constants.mealCellHeight
            } else if isLastMealInSection {
                return Constants.mealCellHeight + Constants.mealSectionSeparatorHeight
            } else {
                return Constants.mealCellHeight + Constants.mealSeparatorHeight
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == viewModel.numberOfDatesLogged() ? 0 : Constants.dateHeaderHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: DashboardDateTableHeaderView.headerFooterIdentifier) as? DashboardDateTableHeaderView else { return nil }
        headerView.viewModel = viewModel.headerViewModel(for: section)
        headerView.isTopHeader = section == 0
        return headerView
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        Main {
            guard let mealEventViewModel = self.viewModel.mealEventDetailsViewModel(at: indexPath) else { return }
            let viewController = MealEventDetailsViewController(viewModel: mealEventViewModel)
            let navController  = UINavigationController(rootViewController: viewController)
            self.present(navController, animated: true, completion: nil)
        }
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateScrollState()
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let currentScrollProgress = scrollView.contentOffset.y / visibleContentOffset
        let targetScrollProgress = targetContentOffset.pointee.y / visibleContentOffset

        let shouldMakeVisible = (targetScrollProgress <= 1 && targetScrollProgress >= 0) || (currentScrollProgress <= 1 && viewMode == .docked)
        if shouldMakeVisible {
            let limit: CGFloat = Constants.dockThreshhold
            guard targetScrollProgress <= limit else {
                // Undock
                viewMode = .visible
                targetContentOffset.pointee = CGPoint(x: 0, y: visibleContentOffset)
                return
            }

            viewMode = .docked
            targetContentOffset.pointee = .zero
        } else if targetScrollProgress > 1,
            targetScrollProgress < scrollProgressForFullscreen {
            viewMode = .fullscreen
            if velocity == .zero {
                targetContentOffset.pointee.y = fullscreenContentOffset
            }
        }
    }

    // MARK: - DashboardTableViewCellDelegate

    func dashboardTableViewCellDidReport(_ cell: DashboardTableViewCell) {
        guard
            let indexPath = tableView.indexPath(for: cell),
            let reportMealEventViewModel = viewModel.reportMealEventViewModel(at: indexPath)
        else {
            return
        }

        let reportMealEventViewController = ReportMealEventViewController(viewModel: reportMealEventViewModel)
        reportMealEventViewController.modalPresentationStyle = .custom
        reportMealEventViewController.transitioningDelegate = self
        present(reportMealEventViewController, animated: true, completion: nil)
    }
}

extension DashboardViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if presented is ReportMealEventViewController {
            return RoundedModalPresentationController(presentedViewController: presented, presenting: presenting)
        }
        return nil
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is ReportMealEventViewController {
            return ModalFadeAnimationController(direction: .present)
        }
        return nil
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is ReportMealEventViewController {
            return ModalFadeAnimationController(direction: .dismiss)
        }
        return nil
    }
}

public class DashboardTableView: PassThroughTouchTableView {
    public override var contentSize: CGSize {
        didSet {
            let headerHeight = tableHeaderView?.bounds.height ?? 0
            let mealContentsize = contentSize.height - headerHeight
            if mealContentsize < bounds.height {
                contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bounds.height - mealContentsize, right: 0)
            } else {
                contentInset = UIEdgeInsets.zero
            }
        }
    }
}
