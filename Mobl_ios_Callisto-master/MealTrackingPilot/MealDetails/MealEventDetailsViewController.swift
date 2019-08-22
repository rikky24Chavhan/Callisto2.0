//
//  MealEventDetailsViewController.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/22/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Intrepid
import AVFoundation
import Photos

final class MealEventDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private struct Constants {
        static let logMealButtonMinimumFontSize: CGFloat = 16.0
        static let fakeNavigationBarTopSpace: CGFloat = UIDevice.current.isRunningiOS10 ? 5 : -60
        static let defaultCopyrightHeight: CGFloat = 96
    }

    // MARK: - Properties

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logMealButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicatorContainerView: UIView!
    @IBOutlet weak var fakeNavigationBarTopSpaceConstraint: NSLayoutConstraint!

    let viewModel: MealEventDetailsViewModel
    var tapGestureRecognizer: UITapGestureRecognizer?
    var testMealMessageTimer: Timer?

    private let bag = DisposeBag()
    private var notesViewBag = DisposeBag()

    private lazy var itemContainerView: MealEventDetailsTitleView = {
        let titleView = MealEventDetailsTitleView.ip_fromNib()
        return titleView
    }()

    // MARK: - Lifecycle

    init(viewModel: MealEventDetailsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationItem()
        configureTableView()
        configureTableHeaderView()
        configureLogMealButton()
        configureActivityIndicator()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureNavigationItemTitle()
        setupNavigationBar(animated: animated)

        startTestMealMessageLoop()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let gesture = tapGestureRecognizer,
            let navigationBar = navigationController?.navigationBar {
            navigationBar.removeGestureRecognizer(gesture)
            tapGestureRecognizer = nil
        }

        stopTestMealMessageLoop()
    }

    override func viewDidLayoutSubviews() {
        tableView.layoutTableHeaderView()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    // MARK: - Navigation Bar

    private func configureNavigationItem() {
        navigationItem.titleView = itemContainerView
        navigationItem.backBarButtonItem = UIBarButtonItem.emptyBackItem()

        if viewModel.mode == .edit {
            let cancelBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "xButton"), style: .plain, target: self, action: #selector(cancelButtonTapped))
            navigationItem.leftBarButtonItem = cancelBarButtonItem
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem.emptyItem(withWidth: 20)
    }

    private func configureNavigationItemTitle() {
        itemContainerView.configure(viewModel: viewModel)

        // Make sure the that the title is always in the center of the navigation bar
        guard let navigationBar = navigationController?.navigationBar else { return }
        itemContainerView.center = CGPoint(x: navigationBar.frameWidth / 2, y: navigationBar.ip_height / 2)
    }

    private func setupNavigationBar(animated: Bool) {
        guard let navigationBar = navigationController?.navigationBar else { return }

        let duration = animated ? 0.3 : 0.0

        UIView.animate(withDuration: duration) {
            navigationBar.barStyle = .default
            navigationBar.tintColor = .piDenim
            navigationBar.titleTextAttributes = [
                NSAttributedStringKey.font: UIFont.openSansSemiboldFont(size: 17.0),
                NSAttributedStringKey.foregroundColor: UIColor.piDenim
            ]
        }

        if viewModel.canSwapMeal,
            tapGestureRecognizer == nil {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(tapOnFoodTitle))
            gesture.numberOfTapsRequired = 1
            gesture.numberOfTouchesRequired = 1
            navigationBar.addGestureRecognizer(gesture)

            tapGestureRecognizer = gesture
        }

        fakeNavigationBarTopSpaceConstraint.constant = Constants.fakeNavigationBarTopSpace
    }

    @objc private func tapOnFoodTitle() {
        let logMealEventViewModel = viewModel.mealEventViewModel()
        let viewController = LogMealEventViewController(viewModel: logMealEventViewModel)
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: - Table View

    private func configureTableView() {
        tableView.allowsSelection = false

        MealEventDetailsPortionCell.registerNib(tableView)
        MealEventDetailsHeaderView.registerNib(tableView)
        MealEventDetailsNotesView.registerNib(tableView)
        CopyrightTableViewCell.registerNib(tableView)

        tableView.dataSource = self
        tableView.delegate = self

        let viewModelUpdateObservable: Observable<Void> = Observable.combineLatest(
            viewModel.notesViewTextObservable,
            viewModel.formattedDate.asObservable(),
            viewModel.image.asObservable()) { _, _, _ in return } // Don't care about values here, just that something changed
        viewModelUpdateObservable.subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }) >>> bag
    }

    private func configureTableHeaderView() {
        guard viewModel.shouldDisplayTestMealMessages else { return }

        let messageView = MealEventDetailsMessageView.ip_fromNib()
        messageView.configure(withContent: viewModel.currentTestMealMessageContent)
        tableView.tableHeaderView = messageView
    }

    private func configureActivityIndicator() {
        activityIndicator.rx.isAnimating <- viewModel.spinnerIsActive >>> bag
        activityIndicatorContainerView.rx.isHidden <- viewModel.spinnerIsActive.map { !$0 } >>> bag
    }

    fileprivate func refreshNotesView(animated: Bool) {
        if viewModel.isAddNoteButtonEmphasized {
            tableView.setContentOffset(tableView.maxContentOffset, animated: animated)
        }

        After(animated ? 0.1 : 0) {
            let notesRow = self.viewModel.shouldDisplayPortion ? 1 : 0
            let indexPath = IndexPath(row: notesRow, section: 0)
            guard let notesView = self.tableView.cellForRow(at: indexPath) as? MealEventDetailsNotesView else { return }
            notesView.configure(with: self.viewModel, animated: animated)
        }
    }

    // MARK: - Test Meal Message Content

    private func startTestMealMessageLoop() {
        guard viewModel.shouldDisplayTestMealMessages else { return }

        testMealMessageTimer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(testMealMessageTimerFired), userInfo: nil, repeats: true)
    }

    private func stopTestMealMessageLoop() {
        guard viewModel.shouldDisplayTestMealMessages else { return }

        testMealMessageTimer?.invalidate()
        testMealMessageTimer = nil
    }

    @objc private func testMealMessageTimerFired(_ timer: Timer) {
        guard let messageView = tableView.tableHeaderView as? MealEventDetailsMessageView else { return }

        let content = viewModel.advanceToNextTestMealMessage()
        messageView.configure(withContent: content, animated: true)
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section > 0 {
            return 1
        } else {
            return viewModel.shouldDisplayPortion ? 2 : 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CopyrightTableViewCell.cellIdentifier, for: indexPath) as! CopyrightTableViewCell

            if !viewModel.shouldDisplayPortion {
                cell.configure(with: UIView(frame: .zero), distanceFromBottom: 10)
            }

            return cell
        } else if viewModel.shouldDisplayPortion && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: MealEventDetailsPortionCell.cellIdentifier, for: indexPath)

            if let portionCell = cell as? MealEventDetailsPortionCell {
                portionCell.configure(with: viewModel.portion.value)
                portionCell.segmentedSlider.isUserInteractionEnabled = viewModel.canEditMeal
                portionCell.delegate = self
            }

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: MealEventDetailsNotesView.cellIdentifier, for: indexPath) as! MealEventDetailsNotesView
            cell.delegate = self
            cell.configure(with: viewModel)

            // The cell has the content view in front of the content blocking the gesture recognition, so hide it
            cell.contentView.isHidden = true

            return cell
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return section > 0 ? 0 : MealEventDetailsHeaderView.estimatedHeight
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section > 0 ? 0 : UITableViewAutomaticDimension
    }


    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return nil }

        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: MealEventDetailsHeaderView.headerFooterIdentifier)

        if let mealEventDetailsHeaderView = headerView as? MealEventDetailsHeaderView {
            mealEventDetailsHeaderView.delegate = self
            mealEventDetailsHeaderView.configure(with: viewModel)
        }
        return headerView
    }


    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section > 0 {
            return Constants.defaultCopyrightHeight
        } else if viewModel.shouldDisplayPortion && indexPath.row == 0 {
            return MealEventDetailsPortionCell.preferredHeight
        } else {
            return MealEventDetailsNotesView.estimatedHeight
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section > 0 {
            guard let firstSectionHeaderHeight = tableView.headerView(forSection: 0)?.frame.height else { return Constants.defaultCopyrightHeight }

            let messageViewHeight: CGFloat = tableView.tableHeaderView?.frame.height ?? 0
            let logMealButtonHeight = logMealButton.isHidden ? 0 : logMealButton.bounds.height
            var portionDetailsHeight: CGFloat = 0
            var mealNotesHeight: CGFloat = 0

            if viewModel.shouldDisplayPortion {
                portionDetailsHeight = MealEventDetailsPortionCell.preferredHeight
                mealNotesHeight = tableView.cellForRow(at: IndexPath(row: 1, section: 0))?.frame.height ?? 0
            } else {
                mealNotesHeight = tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.frame.height ?? 0
            }
            let contentHeight = messageViewHeight + firstSectionHeaderHeight + portionDetailsHeight + mealNotesHeight
            var proposedHeight = tableView.frame.height - contentHeight + logMealButtonHeight
            if viewModel.confirmationButtonIsVisible.value {
                // UI hack to allow the copyright details to show above button initially on test meals
                proposedHeight -= logMealButtonHeight / 2 + 5
            }

            return proposedHeight > Constants.defaultCopyrightHeight ? proposedHeight : Constants.defaultCopyrightHeight
        } else if viewModel.shouldDisplayPortion && indexPath.row == 0 {
            return MealEventDetailsPortionCell.preferredHeight
        } else {
            return UITableViewAutomaticDimension
        }
    }

    // MARK: - Action: Confirm

    private func configureLogMealButton() {
        // Configure font size adjustment
        if let label = logMealButton.titleLabel {
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = Constants.logMealButtonMinimumFontSize / label.font.pointSize    // Scale down to 16pt
        }

        logMealButton.setAttributedTitle(viewModel.logButtonAttributedString, for: .normal)

        viewModel.confirmationButtonIsEnabled.asObservable().subscribe(onNext: { [weak self] confirmationButtonEnabled in
            guard let welf = self else { return }

            welf.logMealButton.isEnabled = confirmationButtonEnabled
            welf.logMealButton.setBackgroundImage(confirmationButtonEnabled ? #imageLiteral(resourceName: "nextStepButtonBackground") : #imageLiteral(resourceName: "nextStepButtonDisabledBackground"), for: .normal)
        }) >>> bag

        viewModel.confirmationButtonIsVisible.asObservable().subscribe(onNext: { [weak self] dataChanged in
            guard let welf = self else { return }

            if dataChanged {
                welf.logMealButton.isHidden = false
            }

            UIView.animate(
                withDuration: 0.2,
                delay: 0.0,
                animations: {
                    welf.logMealButton.alpha = dataChanged ? 1 : 0
            },
                completion: { _ in
                    let copyrightBufferSpace: CGFloat = 32
                    welf.logMealButton.isHidden = !dataChanged
                    var inset = welf.tableView.contentInset
                    inset.bottom = welf.logMealButton.isHidden ? 0 : welf.logMealButton.bounds.height - copyrightBufferSpace
                    welf.tableView.contentInset = inset
                    inset.bottom = welf.logMealButton.isHidden ? 0 : welf.logMealButton.bounds.height - copyrightBufferSpace
                    welf.tableView.scrollIndicatorInsets = inset
            })
        }) >>> bag

        viewModel.syncResult.subscribe(onNext: { [weak self] syncResult in
            guard let syncResult = syncResult else {
                return
            }

            if let error = syncResult.errorToLog() {
                self?.logSynchronizationError(error)
            }

            if let message = syncResult.alertMessage() {
                let alert = UIAlertController.errorAlertController(withMessage: message) {
                    self?.exit()
                }
                self?.present(alert, animated: true, completion: nil)
            } else {
                self?.exit()
            }
        }) >>> bag
    }

    @IBAction func logMealButtonPressed(_ sender: UIButton) {
        viewModel.confirmDetails()
    }

    private func logSynchronizationError(_ error: Error) {
        print("Error logging meal: \(error)")
    }

    @objc private func cancelButtonTapped() {
        if viewModel.changesWereMade {
            let alertViewModel = viewModel.cancelChangesAlertViewModel { [weak self] shouldDismissView in
                guard let welf = self else { return }
                if shouldDismissView {
                    welf.exit(animated: true)
                }
            }
            let alert = UIAlertController(viewModel: alertViewModel)
            present(alert, animated: true, completion: nil)
        } else {
            exit(animated: true)
        }
    }

    private func exit(animated: Bool = true) {
        dismiss(animated: animated, completion: nil)
    }
}

extension MealEventDetailsViewController: MealEventDetailsHeaderViewDelegate {
    func mealEventDetailsHeaderViewDateSelected(_ view: MealEventDetailsHeaderView) {
        let datePickerViewController = DatePickerViewController(date: viewModel.currentLogDate)
        datePickerViewController.delegate = self
        present(datePickerViewController, animated: true, completion: nil)
    }

    func mealEventDetailsHeaderViewPhotoSelected(_ view: MealEventDetailsHeaderView) {
        guard let image = viewModel.image.value else { return }

        let imageViewerViewController = ImageViewerViewController(image: image)
        imageViewerViewController.modalPresentationStyle = .overFullScreen
        present(imageViewerViewController, animated: true, completion: nil)
    }

    func mealEventDetailsHeaderViewPhotoOptionsSelected(_ view: MealEventDetailsHeaderView) {
        showImagePickerActionSheet()
    }
}

extension MealEventDetailsViewController: MealEventDetailsPortionCellDelegate {
    func portionCell(_ cell: MealEventDetailsPortionCell, didSelectPortion portion: MealEventPortion) {
        viewModel.portion.value = portion
        refreshNotesView(animated: true)
    }
}

extension MealEventDetailsViewController: MealEventDetailsNotesViewDelegate {
    func mealEventDetailsNotesViewDidSelectAddNote(_ view: MealEventDetailsNotesView) {
        let notesController = MealEventNotesEntryViewController(viewModel: viewModel.notesEntryViewModel)
        navigationController?.pushViewController(notesController, animated: true)
    }
}

extension MealEventDetailsViewController: DatePickerViewControllerDelegate {
    func datePickerViewControllerDidCancel(_ viewController: DatePickerViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }

    func datePickerViewController(_ viewController: DatePickerViewController, didSelect date: Date) {
        viewModel.currentLogDate = date
        viewController.dismiss(animated: true, completion: nil)
    }
}

extension MealEventDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func showImagePickerActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        var actions = [UIAlertAction]()

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Take a Photo", style: .default) { _ in
                AVCaptureDevice.requestAccess(for: .video) { result in
                    guard result else { return }
                    Main {
                        self.showImagePicker(forSourceType: .camera)
                    }
                }
            }
            actions.append(cameraAction)
        }

        let albumAction = UIAlertAction(title: "Choose From Library", style: .default) { _ in
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else { return }
                Main {
                    self.showImagePicker(forSourceType: .photoLibrary)
                }
            }
        }
        actions.append(albumAction)

        if viewModel.image.value != nil {
            let removePhotoAction = UIAlertAction(title: "Remove Photo", style: .destructive) { _ in
                self.viewModel.image.value = nil
            }
            actions.append(removePhotoAction)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actions.append(cancelAction)

        actions.forEach(actionSheet.addAction)

        present(actionSheet, animated: true, completion: nil)
    }

    func showImagePicker(forSourceType sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.modalPresentationStyle = .overCurrentContext
        picker.delegate = self
        picker.resetNavigationBarStyle()
        present(picker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            viewModel.image.value = selectedImage

            if picker.sourceType == .camera {
                UIImageWriteToSavedPhotosAlbum(selectedImage, nil, nil, nil)
            }
        }
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension MealEventDetailsViewController: LogMealEventViewControllerDelegate {
    func logMealEventViewControllerSaveButtonTapped(_ viewController: LogMealEventViewController, withMeal meal: Meal) {
        viewModel.meal.value = meal
        viewController.navigationController?.popViewController(animated: true)
    }
}

fileprivate extension SaveResult {
    fileprivate func alertMessage() -> String? {
        switch self {
        case .synchronized, .localOnly:
            return nil
        default:
            return "We're sorry, but we were unable to log your meal. Contact your study coordinator for assistance."
        }
    }

    fileprivate func errorToLog() -> Error? {
        switch self {
        case .localOnly(_, let error):
            return error
        case .remoteOnly(_, let error):
            return error
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
}

fileprivate extension MealEventDetailsMessageView {
    func configure(withContent content: MealEventDetailsViewModel.TestMealMessageContent, animated: Bool = false) {
        configure(withImage: content.image, text: content.text, animated: animated)
    }
}

extension UIImagePickerController {
    fileprivate func resetNavigationBarStyle() {
        navigationBar.barStyle = .default
        navigationBar.isTranslucent = false
    }
}
