//
//  DashboardViewModel.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/14/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift


fileprivate struct Section {
    let headerViewModel: DashboardHeaderViewModel
    private var cellViewModels: [DashboardTableViewCellViewModel]

    var numberOfMeals: Int {
        return cellViewModels.count
    }

    init(date: Date, mealEvents: [MealEvent], stats: MealStatistics) {
        headerViewModel = DashboardDateHeaderViewModel(date: date)
        cellViewModels = []
        mealEvents.forEach { cellViewModels.append(DashboardTableViewCellViewModel(mealEvent: $0, stats: stats)) }
    }

    func cellViewModel(at row: Int) -> DashboardTableViewCellViewModel? {
        guard cellViewModels.count > row else { return nil }
        return cellViewModels[row]
    }
}

public final class DemoDashboardViewModel: DashboardViewModel {

    override var mealButtonDockedHeight: CGFloat {
        return UIDevice.current.isSmallHeight ? 54 : 80
    }

    override var initialWelcomeViewTopConstant: CGFloat {
        return UIDevice.current.isSmall ? 45 : 80
    }

    // MARK: - Properties

    override var backgroundGradientSpec: GradientSpec {
        return GradientSpec(direction: .topLeftToBottomRight,
                            colors: [
                                UIColor.piMetallicBlue,
                                UIColor.piDreBlue,
                                UIColor.piGreyblueTwo,
                                UIColor.piLightBlueGrey],
                            locations: [0.0, 0.25, 0.75, 1.0])
    }

    override var homeButtonGradientDirection: GradientView.Direction {
        return .horizontal
    }

    override var homeButtonNormalBackgroundColors: [UIColor] {
        return [
            UIColor.piGreyishBlue,
            UIColor.piLightBlueGreyThree,
        ]
    }

    override var homeButtonHighlightedBackgroundColors: [UIColor] {
        return [
            UIColor.piGreyishBlue,
            UIColor.piLightBlueGreyThree,
        ]
    }

    override var shouldDisplaySettingsButton: Bool {
        return false
    }

    override var weekdayName: String {
        return "DEMO"
    }

    override var logMessage: Observable<NSAttributedString> {
        return stateObservable.map({ (testCount: Int, commonCount: Int, hasDisplayedLoggedMeals: Bool) -> NSAttributedString in
            let mealCount = testCount + commonCount
            if mealCount == 0 {
                return DashboardViewModel.applyLogMessageStyle(to: "Let’s get started!")
            } else {
                let mealCountText = "\(mealCount)"
                let countSuffix = mealCount > 1 ? "s" : ""
                let message = "You have logged \(mealCountText) meal\(countSuffix) for practice."
                let rangeOfNumberOfMealEvents = (message as NSString).range(of: mealCountText)
                return DashboardViewModel.applyLogMessageStyle(to: message, boldRange: rangeOfNumberOfMealEvents)
            }
        })
    }

    override var suggestionMessage: Observable<NSAttributedString> {
        return stateObservable.map({ (testCount: Int, commonCount: Int, hasDisplayedLoggedMeals: Bool) -> String in
            switch (testCount, commonCount, hasDisplayedLoggedMeals) {
            case (0, 0, false):
                return "Let’s log a Test Meal for practice. Your coordinator will help you out."
            case (1, 0, false):
                return "You are doing great! Swipe up to see the meal you just logged."
            case (1, 0, true):
                return "Great! Now let’s log a Common Meal."
            default:
                return "Feel free to keep logging meals for practice. Let me know when you are ready to end the demo."
            }
        }).map({ DashboardViewModel.applySuggestionMessageStyle(to: $0 ) })
    }

    override var shouldDisplayActionButton: Observable<Bool> {
        return stateObservable.map({ (testCount: Int, commonCount: Int, hasDisplayedLoggedMeals: Bool) -> Bool in
            return testCount > 0 && commonCount > 0 && hasDisplayedLoggedMeals
        })
    }

    override var canLogTestMeal: Observable<Bool> {
        return stateObservable.map({ (testCount: Int, commonCount: Int, hasDisplayedLoggedMeals: Bool) -> Bool in
            return testCount == 0 || commonCount > 0
        })
    }

    override var canLogCommonMeal: Observable<Bool> {
        return stateObservable.map({ (testCount: Int, commonCount: Int, hasDisplayedLoggedMeals: Bool) -> Bool in
            return testCount > 0 && hasDisplayedLoggedMeals
        })
    }

    private var stateObservable: Observable<(testCount: Int, commonCount: Int, hasDisplayedLoggedMeals: Bool)> = Observable.just((0, 0, false))

    // MARK: - Lifecycle

    override init(
        keychain: KeychainDataStorage,
        mealDataController: MealDataController,
        userProvider: UserProviding,
        loginClient: LoginClient,
        action: (() -> Void)? = nil
        ) {
        super.init(keychain: keychain, mealDataController: mealDataController, userProvider: userProvider, loginClient: loginClient, action: action)

        setUpObservers()
    }

    private func setUpObservers() {
        let didDisplayPopulatedMeals = mealJournalIsDocked.asObservable()
            .skipUntil(mealDataController.loggedMealEvents.filter({ !$0.isEmpty }))
            .filter({ $0 })
            .distinctUntilChanged()
        stateObservable = Observable.combineLatest(mealDataController.loggedMealEvents,
                                                   Observable.just(false).concat(didDisplayPopulatedMeals),
                                                   resultSelector: { (mealEvents: [MealEvent], hasDisplayedLoggedMeals: Bool) -> (Int, Int, Bool) in
                                                    return (
                                                        testCount: mealEvents.filter({ $0.classification == .test }).count,
                                                        commonCount: mealEvents.filter({ $0.classification == .common }).count,
                                                        hasDisplayedLoggedMeals: hasDisplayedLoggedMeals
                                                    )
        }).share(replay: 1, scope: .forever)
    }
}

public class DashboardViewModel: ReportMealEventViewModelDelegate {

    var mealButtonDockedHeight: CGFloat {
        return UIDevice.current.isSmall ? 74 : 80
    }

    var initialWelcomeViewTopConstant: CGFloat {
        return 80
    }

    // MARK: - Properties

    var backgroundGradientSpec: GradientSpec {
        return GradientSpec(direction: .topLeftToBottomRight,
                            colors: [
                                UIColor.piCornflower,
                                UIColor.piCornflowerTwo,
                                UIColor.piSkyBlue],
                            locations: [0.0, 0.5, 1.0])
    }

    var homeButtonGradientDirection: GradientView.Direction {
        return .vertical
    }

    var homeButtonNormalBackgroundColors: [UIColor] {
        return [
            UIColor.piDarkSkyBlue,
            UIColor.piCornflower
        ]
    }

    var homeButtonHighlightedBackgroundColors: [UIColor] {
        return [
            UIColor.piBluish,
            UIColor.piBlueyPurple
        ]
    }

    private var sections = [Section]()

    fileprivate var keychain: KeychainDataStorage
    fileprivate let mealDataController: MealDataController
    fileprivate let userProvider: UserProviding
    fileprivate let loginClient: LoginClient
    let action: (() -> Void)?

    var getCurrentDate: () -> Date = {
        return Date()
    }

    var shouldDisplaySettingsButton: Bool {
        return true
    }

    var weekdayName: String {
        return getCurrentDate().weekdayName
    }

    var mealJournalIsEmpty = Variable<Bool>(false)
    var mealJournalIsDocked = Variable<Bool>(false)

    private func mealEventCountSinceDate(_ startDate: Date, endDate: Date? = nil) -> Observable<Int> {
        return mealDataController.loggedMealEvents.map { mealEvents in
            let endDate = endDate ?? Date.distantFuture
            let mealEventsSinceStartDate = mealEvents.filter { $0.date >= startDate && $0.date < endDate }
            return mealEventsSinceStartDate.count
        }
    }

    private var currentDayMealEventCount: Observable<Int> {
        return mealEventCountSinceDate(getCurrentDate().startOfDay)
    }

    private var previousDayMealEventCount: Observable<Int> {
        let startOfDay = getCurrentDate().startOfDay
        let previousStartOfDay = startOfDay.adjustDays(noOfDays: -1)
        return mealEventCountSinceDate(previousStartOfDay, endDate: startOfDay)
    }

    private var currentWeekMealEventCount: Observable<Int> {
        return mealEventCountSinceDate(getCurrentDate().startWeek)
    }

    var logMessage: Observable<NSAttributedString> {
        return currentDayMealEventCount.map { count in
            let message: String
            if count == 0 {
                message = "You haven't logged any meals today yet."
            } else {
                let mealCountText: String
                if count == 1 {
                    mealCountText = "a meal"
                } else {
                    mealCountText = "\(count) meals"
                }
                message = "You logged \(mealCountText) today. Keep it up!"
            }

            return DashboardViewModel.applyLogMessageStyle(to: message)
        }
    }

    var suggestionMessage: Observable<NSAttributedString> {
        return Observable.combineLatest(currentWeekMealEventCount, currentDayMealEventCount, previousDayMealEventCount) { (weekCount, currentDayCount, previousDayCount) in
            let isStartOfWeek = self.getCurrentDate().startOfDay == self.getCurrentDate().startWeek
            let shouldInformMissedLoggingYesterday = !isStartOfWeek && previousDayCount == 0 && currentDayCount == 0
            let previousDayPrefix = shouldInformMissedLoggingYesterday ? "You seem to have missed logging yesterday. Great to have you back!\n" : ""

            let weekMessage: String
            if weekCount == 0 {
                weekMessage = "You haven't logged any meals this week yet."
            } else {
                let mealCountText: String
                if weekCount == 1 {
                    mealCountText = "1 meal"
                } else {
                    mealCountText = "\(weekCount) meals"
                }
                weekMessage = "You logged \(mealCountText) so far this week."
            }
            let message = previousDayPrefix + weekMessage
            return DashboardViewModel.applySuggestionMessageStyle(to: message)
        }
    }

    var shouldDisplayActionButton: Observable<Bool> {
        return Observable.just(false)
    }

    var canLogTestMeal: Observable<Bool> {
        return Observable.just(true)
    }

    var canLogCommonMeal: Observable<Bool> {
        return Observable.just(true)
    }

    var footerViewAlpha: Observable<CGFloat> {
        return mealJournalIsEmpty.asObservable().map { $0 ? 0 : 1 }
    }

    var emptyViewAlpha: Observable<CGFloat> {
        return mealJournalIsEmpty.asObservable().map { $0 ? 1 : 0 }
    }

    var shouldDisplayEndOfListView: Observable<Bool> {
        return mealJournalIsEmpty.asObservable().map { !$0 }
    }

    var shouldHideBlockingActivityIndicator: Observable<Bool> {
        return isLoggingOut.asObservable().map { !$0 }
    }

    private var isLoggingOut = Variable(false)  // Google logout is async, need to block UI while in progress

    private(set) var tableUpdateObservable = Observable<Void>.just({}())

    // MARK: - Lifecycle

    init(
        keychain: KeychainDataStorage,
        mealDataController: MealDataController,
        userProvider: UserProviding,
        loginClient: LoginClient,
        action: (() -> Void)? = nil
    ) {
        self.keychain = keychain
        self.mealDataController = mealDataController
        self.userProvider = userProvider
        self.loginClient = loginClient
        self.action = action

        setUpObservers()
    }

    private func setUpObservers() {
        tableUpdateObservable = mealDataController.loggedMealEvents.map { [weak self] mealEvents in
            guard let welf = self else {
                return
            }

            let statistics = MealStatistics(mealEvents: mealEvents)
            welf.generateSections(mealEvents: mealEvents, withStatistics: statistics)
            welf.updateAnimateReportCompletionState()
            welf.mealJournalIsEmpty.value = mealEvents.count == 0
        }
    }

    // MARK: Applying Styles

    fileprivate static func applyLogMessageStyle(to message: String, boldRange: NSRange? = nil) -> NSAttributedString {
        let fontSize: Float = UIDevice.current.isSmall ? 22 : 36
        let attributedString = NSMutableAttributedString(string: message)
        attributedString.addAttributes(
            [
                NSAttributedString.Key.font : UIFont.openSansLightFont(size: fontSize),
                NSAttributedString.Key.foregroundColor : UIColor.piWhite
            ],
            range: NSRange(location: 0, length: message.count)
        )
        if let boldRange = boldRange {
            attributedString.addAttributes(
                [
                    NSAttributedString.Key.font : UIFont.openSansFont(size: fontSize),
                    NSAttributedString.Key.foregroundColor : UIColor.piWhite
                ],
                range: boldRange
            )
        }
        return attributedString
    }

    fileprivate static func applySuggestionMessageStyle(to message: String) -> NSAttributedString {
        return NSAttributedString(
            string: message,
            attributes: [
                NSAttributedString.Key.font : UIFont.openSansSemiboldFont(size: UIDevice.current.isSmallHeight ? 14 : 16),
                NSAttributedString.Key.foregroundColor : UIColor.white
            ]
        )
    }

    // MARK: - Networking

    func getMeals(completion: voidRequestCompletion?) {
        mealDataController.getLoggedMealEvents(completion: completion)
    }

    // MARK: - Meal Journal Table

    fileprivate func mealSection(for section: Int) -> Section? {
        guard sections.count > section else { return nil }
        return sections[section]
    }

    func numberOfDatesLogged() -> Int {
        return sections.count
    }

    func numberOfMealsLogged() -> Int {
        return sections.reduce(0, { $0 + $1.numberOfMeals })
    }

    func numberOfMeals(for section: Int) -> Int {
        guard let dataSection = mealSection(for: section) else { return 0 }
        return dataSection.numberOfMeals
    }

    func cellViewModel(at indexPath: IndexPath) -> DashboardTableViewCellViewModel? {
        guard let mealSection = mealSection(for: indexPath.section) else { return nil }
        return mealSection.cellViewModel(at: indexPath.row)
    }

    func headerViewModel(for section: Int) -> DashboardHeaderViewModel? {
        guard let mealSection = mealSection(for: section) else { return nil }
        return mealSection.headerViewModel
    }

    private func generateSections(mealEvents: [MealEvent], withStatistics stats: MealStatistics) {
        var mealEventsByDate = [Date : [MealEvent]]()
        mealEvents.forEach { mealEvent in
            let startOfDay = mealEvent.date.startOfDay
            var groupedMealEvents = mealEventsByDate[startOfDay] ?? []
            groupedMealEvents.append(mealEvent)
            mealEventsByDate[startOfDay] = groupedMealEvents
        }

        sections = mealEventsByDate
            .sorted { $0.key < $1.key }
            .map { date, mealEvents in
                return Section(date: date, mealEvents: mealEvents, stats: stats)
            }
            .reversed()
    }

    private func updateAnimateReportCompletionState() {
        defer {
            mealEventToAnimateReportCompletion = nil
        }

        for section in sections {
            for index in 0..<section.numberOfMeals {
                guard let viewModel = section.cellViewModel(at: index) else { continue }
                if viewModel.mealEvent.localIdentifier == mealEventToAnimateReportCompletion?.localIdentifier {
                    viewModel.shouldAnimateReportCompletion = true
                    return
                }
            }
        }
    }

    // MARK: - Log Meal Event View Model

    func logMealEventViewModel(mealClassification: MealClassification) -> LogMealEventViewModel {
        return LogMealEventViewModel(mealDataController: mealDataController, mealClassification: mealClassification)
    }

    // MARK: Meal Creation

    func mealEventDetailsViewModel(at indexPath: IndexPath) -> MealEventDetailsViewModel? {
        guard let mealEvent = cellViewModel(at: indexPath)?.mealEvent.copy() as? MealEvent else { return nil }
        return MealEventDetailsViewModel(mealEvent: mealEvent, dataController: mealDataController, mode: .edit)
    }

    // MARK: - Report Meal Event

    func reportMealEventViewModel(at indexPath: IndexPath) -> ReportMealEventViewModel? {
        guard let mealEvent = cellViewModel(at: indexPath)?.mealEvent else { return nil }
        return ReportMealEventViewModel(mealEvent: mealEvent, dataController: mealDataController, delegate: self)
    }

    // MARK: - ReportMealEventViewModelDelegate

    var mealEventToAnimateReportCompletion: MealEvent?

    func reportMealEventViewModelDidReport(_ viewModel: ReportMealEventViewModel) {
        mealEventToAnimateReportCompletion = viewModel.mealEvent
    }
}
