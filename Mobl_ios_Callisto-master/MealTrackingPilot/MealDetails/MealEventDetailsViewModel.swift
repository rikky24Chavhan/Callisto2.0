//
//  MealEventDetailsViewModel.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/23/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import RxSwift
import Intrepid
import AlamofireImage
import RealmSwift
import SwiftDate
import KeychainAccess

final class MealEventDetailsViewModel: MealEventNotesEntryViewModelDelegate {

    // MARK: - Lifecycle

    private let mealEvent: MealEvent
    private let dataController: MealDataController
    private(set) var mode: LogMealEventMode

    var title: String {
        return meal.value.name
    }

    var mealLocationAndPortion: String? {
        guard let location = meal.value.location else { return nil }

        let roundedPortionOuncesString = "\(Int(meal.value.portionOunces))"
        return location + " • " + roundedPortionOuncesString + "oz"
    }

    var canEditMeal: Bool {
        return Date() < mealEvent.date + 2.days
    }

    var canSwapMeal: Bool {
        return canEditMeal && mode == .edit
    }

    var hasImage: Bool {
        return image.value != nil
    }

    var hasNote: Bool {
        return !(notes.value?.isEmpty ?? true)
    }

    var logButtonAttributedString: NSAttributedString {
        switch mode {
        case .create:
            let attributedString = NSMutableAttributedString(string: "Log \(mealEvent.meal.name)")
            attributedString.addAttributes(
                [
                    NSAttributedStringKey.font : UIFont.openSansSemiboldFont(size: 18),
                    NSAttributedStringKey.foregroundColor : UIColor.white
                ],
                range: NSMakeRange(0, attributedString.string.count)
            )
            return attributedString
        case .edit:
            if canEditMeal {
                let attributedString = NSMutableAttributedString(string: "Save All Changes")
                attributedString.addAttributes(
                    [
                        NSAttributedStringKey.font : UIFont.openSansSemiboldFont(size: 20),
                        NSAttributedStringKey.foregroundColor : UIColor.white
                    ],
                    range: NSMakeRange(0, attributedString.string.count)
                )
                return attributedString
            } else {
                let attributedString = NSMutableAttributedString(string: "Meals can't be edited after 48 hours")
                attributedString.addAttributes(
                    [
                        NSAttributedStringKey.font : UIFont.openSansItalicFont(size: 16),
                        NSAttributedStringKey.foregroundColor : UIColor.white
                    ],
                    range: NSMakeRange(0, attributedString.string.count)
                )
                return attributedString
            }
        }
    }

    private var logDate: Variable<Date>

    let formattedDate: Variable<NSAttributedString>
    var currentLogDate: Date {
        get {
            return logDate.value
        }
        set {
            logDate.value = newValue
        }
    }

    var meal: Variable<Meal>
    var image: Variable<UIImage?>
    var originalImage: Variable<UIImage?>
    var portion: Variable<MealEventPortion>
    var notes: Variable<String?>
    private var imageURL: URL?
    private var imageData: Data?

    var notesEntryViewModel: MealEventNotesEntryViewModel {
        return MealEventNotesEntryViewModel(mealName: meal.value.name, notes: notes.value, delegate: self)
    }

    var changesWereMade: Bool {
        return confirmationButtonIsVisible.value && confirmationButtonIsEnabled.value
    }

    private var synchronizing = Variable(false)
    private var lastSyncResult: Variable<SaveResult<MealEvent>?> = Variable(nil)

    private(set) var syncResult: Observable<SaveResult<MealEvent>?>
    private(set) var spinnerIsActive: Observable<Bool>
    private(set) var confirmationButtonIsEnabled = Variable<Bool>(true)
    private(set) var confirmationButtonIsVisible = Variable<Bool>(true)

    private let bag = DisposeBag()
    private let imageDownloader: ImageDownloader

    // MARK: - Lifecycle

    init(
        mealEvent: MealEvent,
        dataController: MealDataController,
        imageDownloader: ImageDownloader = ImageDownloader.default,
        mode: LogMealEventMode = .create) {

        self.mealEvent = mealEvent
        self.dataController = dataController
        self.imageDownloader = imageDownloader
        self.mode = mode

        meal = Variable(mealEvent.meal)
        logDate = Variable(mealEvent.date)
        image = Variable(nil)
        originalImage = Variable(nil)
        portion = Variable(mealEvent.portion)
        notes = Variable(mealEvent.note)
        formattedDate = Variable(NSAttributedString(string: ""))
        imageURL = mealEvent.imageURL
        imageData = nil

        syncResult = lastSyncResult.asObservable()
        spinnerIsActive = synchronizing.asObservable()

        confirmationButtonIsEnabled <- Observable.combineLatest(
            lastSyncResult.asObservable(),
            synchronizing.asObservable(),
            resultSelector: { syncResult, synchronizing -> Bool in
                if !self.canEditMeal {
                    return false
                }

                if let syncResult = syncResult {
                    switch syncResult {
                    case .synchronized(_):
                        return false
                    default:
                        break
                    }
                }
                return !synchronizing
            }) >>> bag

        formattedDate.value = format(date: logDate.value)

        logDate.asObservable().subscribe(onNext: { [weak self] date in
            guard let welf = self else { return }
            welf.formattedDate.value = welf.format(date: date)
        }) >>> bag

        if mode == .edit {
            if let imageURLRequest = mealEvent.imageURLRequest {
                imageDownloader.download(imageURLRequest, completion: { [weak self] response in
                    guard let welf = self else { return }
                    if let image = response.result.value {
                        welf.originalImage.value = image
                        welf.image.value = image
                    }
                })
            }

            if !canEditMeal {
                confirmationButtonIsVisible.value = true
                return
            }
            confirmationButtonIsVisible.value = false

            let dataChangedObserver: Observable<Bool> = Observable.combineLatest(
                notes.asObservable(),
                logDate.asObservable(),
                portion.asObservable(),
                image.asObservable(),
                meal.asObservable(), resultSelector: { note, logDate, portion, image, meal -> Bool in
                    return ((note != self.mealEvent.note) || (logDate != self.mealEvent.date) || (portion != self.mealEvent.portion) || (image != self.originalImage.value) || (meal.name != self.mealEvent.meal.name))
            })

            dataChangedObserver.subscribe(onNext: { [weak self] dataChanged in
                guard let welf = self else { return }
                welf.confirmationButtonIsVisible.value = dataChanged
            }) >>> bag
        }
    }

    // MARK: - Date

    private func format(date: Date) -> NSAttributedString {
        var dateString: String
        if date.isToday {
            dateString = "Today"
        } else {
            dateString = date.string(custom: "MMM dd")
        }
        dateString = dateString.uppercased()

        let timeString = date.string(custom: "h:mm a")

        let formattedString = "\(dateString) AT \(timeString)"
        let rangeOfDateString = (formattedString as NSString).range(of: dateString)
        let rangeOfTimeString = (formattedString as NSString).range(of: timeString)
        let rangeOfAt = (formattedString as NSString).range(of: "AT")

        let boldAttributes = [
            NSAttributedStringKey.font : UIFont.openSansSemiboldFont(size: 33),
            NSAttributedStringKey.foregroundColor : formattedDateTextColor
        ]
        let lightAttributes = [
            NSAttributedStringKey.font : UIFont.openSansLightFont(size: 33),
            NSAttributedStringKey.foregroundColor : formattedDateTextColor
        ]

        let attributedString = NSMutableAttributedString(string: formattedString)
        attributedString.addAttributes(boldAttributes, range: rangeOfDateString)
        attributedString.addAttributes(boldAttributes, range: rangeOfTimeString)
        attributedString.addAttributes(lightAttributes, range: rangeOfAt)
        return attributedString
    }

    var formattedDateTextColor: UIColor {
        switch meal.value.classification {
        case .common:
            return UIColor.piTopaz
        case .test:
            return UIColor.piLightOrange
        }
    }

    var isDateContainerUserInteractionEnabled: Bool {
        return canEditMeal
    }

    // MARK: - Image

    var addPhotoButtonBackgroundColor: UIColor {
        return canEditMeal ? UIColor.piPaleGreyTwo : UIColor.white
    }

    var addPhotoButtonShadowOpacity: Float {
        return (canEditMeal && !hasImage) ? 0.06 : 0
    }

    var addPhotoButtonTitleFont: UIFont {
        return canEditMeal ? UIFont.openSansSemiboldFont(size: 18) : UIFont.openSansBoldFont(size: 18)
    }

    var isAddPhotoButtonEnabled: Bool {
        return canEditMeal
    }
    
    var isPhotoImageViewUserInteractionEnabled: Bool {
        return hasImage
    }
    
    var isPhotoOptionsButtonHidden: Bool {
        return !(canEditMeal && hasImage)
    }
    
    // MARK: - Test Meal Message Header

    struct TestMealMessageContent {
        let image: UIImage
        let text: String
    }

    var shouldDisplayTestMealMessages: Bool {
        return mealEvent.classification == .test && mode == .create
    }

    var currentTestMealMessageIndex: Int = 0

    var currentTestMealMessageContent: TestMealMessageContent {
        return testMealMessageContent[currentTestMealMessageIndex]
    }

    let testMealMessageContent: [TestMealMessageContent] = [
        TestMealMessageContent(image: #imageLiteral(resourceName: "testMeal"), text: "This is a test meal. Please keep in mind the following things."),
        TestMealMessageContent(image: #imageLiteral(resourceName: "guideEatPortion"), text: "Please eat the entire portion without any additional foods."),
        TestMealMessageContent(image: #imageLiteral(resourceName: "guideDontEat"), text: "Don’t eat anything again for the next 3 hours."),
        TestMealMessageContent(image: #imageLiteral(resourceName: "guideDontExercise"), text: "Don’t exercise during the next 3 hours.")
    ]

    func advanceToNextTestMealMessage() -> TestMealMessageContent {
        var nextIndex = currentTestMealMessageIndex + 1
        if nextIndex >= testMealMessageContent.count {
            nextIndex = 0
        }

        currentTestMealMessageIndex = nextIndex
        return testMealMessageContent[nextIndex]
    }

    // MARK: - Portion

    var shouldDisplayPortion: Bool {
        return mealEvent.classification == .common
    }

    // MARK: - Notes

    var notesViewText: String? {
        return notes.value ?? ""
    }

    var notesViewTextObservable: Observable<String?> {
        return notes.asObservable()
    }

    var addNoteButtonBackgroundColor: UIColor {
        return canEditMeal ? UIColor.piPaleGreyTwo : UIColor.white
    }

    var addNoteButtonShadowOpacity: Float {
        if isAddNoteButtonEmphasized {
            return 0.2
        } else {
            return (canEditMeal && !hasNote) ? 0.06 : 0
        }
    }

    var addNoteButtonTitleFont: UIFont {
        return canEditMeal ? UIFont.openSansSemiboldFont(size: 18) : UIFont.openSansBoldFont(size: 18)
    }

    var isAddNoteContainerViewHidden: Bool {
        return hasNote
    }

    var isAddNoteButtonEnabled: Bool {
        return canEditMeal
    }

    var isNotesContainerViewHidden: Bool {
        return !hasNote
    }

    var isNotesContainerViewUserInteractionEnabled: Bool {
        return canEditMeal
    }
    
    var notesContainerViewBackgroundColor: UIColor {
        return canEditMeal ? UIColor.piDenim.withAlphaComponent(0.05) : UIColor.white
    }

    var isNoteSuggestionViewHidden: Bool {
        return !canEditMeal || hasNote
    }

    var isAddNoteButtonEmphasized: Bool {
        return canEditMeal && portion.value != .usual
    }

    var addNoteButtonBorderColor: UIColor {
        return isAddNoteButtonEmphasized ? UIColor.piCommonMealGradientStartColor : UIColor.piPaleGreyThree
    }

    var addNoteButtonBorderWidth: CGFloat {
        return isAddNoteButtonEmphasized ? 2.0 : 1.0
    }

    // MARK: - MealEventNotesEntryViewModelDelegate

    func mealEventNotesEntryViewModel(_ viewModel: MealEventNotesEntryViewModel, didSave notes: String?) {
        self.notes.value = notes
    }

    // MARK: - Log Meal

    func confirmDetails() {
        self.imageData = prepareImageData()

        confirmMeal()
        confirmDate()
        confirmPortion()
        confirmNotes()
        confirmImageData()
        confirmImageURL()

        saveMealEvent()
    }

    private func prepareImageData() -> Data? {
        guard let image = image.value else {
            imageURL = nil
            return nil
        }
        guard image != originalImage.value else {
            return nil
        }

        return UIImageJPEGRepresentation(image, 0)
    }

    private func saveMealEvent() {
        synchronizing.value = true
        dataController.saveMealEvent(mealEvent) { [weak self] saveResult in
            self?.lastSyncResult.value = saveResult
            self?.synchronizing.value = false
        }
    }

    private func confirmMeal() {
        mealEvent.meal = meal.value
    }

    private func confirmDate() {
        mealEvent.date = logDate.value
    }

    private func confirmPortion() {
        mealEvent.portion = portion.value
    }

    private func confirmNotes() {
        mealEvent.note = notes.value ?? ""
    }

    private func confirmImageURL() {
        mealEvent.imageURL = imageURL
    }

    private func confirmImageData() {
        // if the image has been removed, pass empty data so that we send an empty string to the backend
        mealEvent.imageData = originalImage.value != nil && image.value == nil ? Data() : imageData
    }

    // MARK: - Change meal event

    func mealEventViewModel() -> LogMealEventViewModel {
        return LogMealEventViewModel(mealDataController: dataController, mealClassification: meal.value.classification, mode: mode, selectedMeal: meal.value)
    }

    // MARK: - Cancel changes Alert

    func cancelChangesAlertViewModel(completion: ((_ dismissView: Bool) -> Void)?) -> UIAlertViewModel {
        return UIAlertViewModel.dismissConfirmationAlertViewModel(
            title: "Do you want to discard your changes?",
            message: "If you leave the screen, the changes you just made won't be saved.",
            confirmButtonTitle: "Discard",
            cancelButtonTitle: "Keep Editing",
            completion: completion)
    }
}

protocol MealEventNotesEntryViewModelDelegate: class {
    func mealEventNotesEntryViewModel(_ viewModel: MealEventNotesEntryViewModel, didSave notes: String?)
}

final class MealEventNotesEntryViewModel {

    let mealName: String

    private let initialNotesValue: String?
    private(set) var notes: Variable<String?>

    var hasNotes: Observable<Bool> {
        return notes.asObservable().map { notes in
            let characterCount = notes?.count ?? 0
            return characterCount > 0
        }
    }

    var changesWereMade: Bool {
        return notes.value != initialNotesValue
    }

    var shouldDisplayDeleteAction: Bool {
        guard let initialNotesValue = initialNotesValue else { return false }
        return !initialNotesValue.isEmpty
    }

    private weak var delegate: MealEventNotesEntryViewModelDelegate?

    init(mealName: String, notes: String?, delegate: MealEventNotesEntryViewModelDelegate) {
        self.mealName = mealName
        self.initialNotesValue = notes
        self.notes = Variable(notes)
        self.delegate = delegate
    }

    func confirm() {
        delegate?.mealEventNotesEntryViewModel(self, didSave: notes.value)
    }

    // MARK: - Cancel changes Alert

    func cancelChangesAlertViewModel(completion: ((_ dismissView: Bool) -> Void)?) -> UIAlertViewModel {
        return UIAlertViewModel.dismissConfirmationAlertViewModel(
            title: "Do you want to discard your note?",
            message: "If you leave the screen, the note you just made won't be saved.",
            confirmButtonTitle: "Discard",
            cancelButtonTitle: "Keep Editing",
            completion: completion)
    }

    func deleteAlertViewModel(completion: ((_ dismissView: Bool) -> Void)?) -> UIAlertViewModel {
        return UIAlertViewModel.dismissConfirmationAlertViewModel(
            title: "Do you want to delete this note?",
            message: "Your coordinator won’t be able to read it anymore.",
            confirmButtonTitle: "Delete Note",
            cancelButtonTitle: "Cancel",
            completion: completion)
    }
}

extension UIAlertViewModel {
    fileprivate class func dismissConfirmationAlertViewModel(
        title: String,
        message: String,
        confirmButtonTitle: String,
        cancelButtonTitle: String,
        completion: ((_ shouldDismissView: Bool) -> Void)?) -> UIAlertViewModel {

        let cancelAction = UIAlertActionViewModel(title: cancelButtonTitle, style: .default) { _ in
            completion?(false)
        }

        let confirmAction = UIAlertActionViewModel(title: confirmButtonTitle, style: .destructive) { _ in
            completion?(true)
        }

        let actions = [confirmAction, cancelAction]

        return UIAlertViewModel(title: title, message: message, preferredStyle: .alert, actionViewModels: actions)
    }
}
