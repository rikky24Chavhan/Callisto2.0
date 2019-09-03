//
//  MealEventNotesEntryViewController.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/24/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import RxSwift
import Intrepid

class MealEventNotesEntryViewController: UIViewController, UITextViewDelegate {
    private struct Constants {
        static let fakeNavBarTopSpace: CGFloat = UIDevice.current.isRunningiOS10 ? -21 : -86
    }

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var textContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var fakeNavBarTopSpaceConstraint: NSLayoutConstraint!

    private let viewModel: MealEventNotesEntryViewModel
    private let bag = DisposeBag()

    private var isCancelling: Bool = false

    init(viewModel: MealEventNotesEntryViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBar()
        setupTextView()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeKeyboard()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unsubscribeKeyboard()
    }

    // MARK: Setup

    private func setupNavBar() {
        fakeNavBarTopSpaceConstraint.constant = Constants.fakeNavBarTopSpace
        setupTitleView()
        setupBackBarButtonItem()
        setupDeleteBarButtonItem()
    }

    private func setupTitleView() {
        let titleView = MealEventDetailsTitleView.ip_fromNib()
        titleView.configure(with: viewModel)
        navigationItem.titleView = titleView
    }

    private func setupBackBarButtonItem() {
        let cancelBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "buttonBackarrow"), style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = cancelBarButtonItem
    }

    private func setupDeleteBarButtonItem() {
        guard viewModel.shouldDisplayDeleteAction else { return }

        let deleteBarButtonItem = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteButtonTapped))
        deleteBarButtonItem.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont.openSansSemiboldFont(size: 17.0),
             NSAttributedString.Key.foregroundColor : UIColor.piDarkishPink],
            for: .normal)
        navigationItem.rightBarButtonItem = deleteBarButtonItem
    }

    private func setupTextView() {
        textView.delegate = self
        textView.configureCustomReturnButton(
            withImage: #imageLiteral(resourceName: "doneButton"),
            disclaimerText: "Please don’t document any sensitive information here. Study coordinators may be reviewing these notes.")
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 16, bottom: textView.customReturnButtonAccessoryViewHeight, right: 16)
    }

    // MARK: ViewModel

    private func bindViewModel() {
        textView.rx.text <-> viewModel.notes >>> bag
        placeholderLabel.rx.isHidden <- viewModel.hasNotes >>> bag
    }

    // MARK: Keyboard

    private func subscribeKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    private func unsubscribeKeyboard() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.size.height else {
            return
        }

        textContainerBottomConstraint.constant = keyboardHeight - textView.customReturnButtonAccessoryViewHeight

        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.0
        UIView.animate(withDuration: duration, animations: view.layoutIfNeeded)
    }

    // MARK: UITextViewDelegate

    func textViewDidEndEditing(_ textView: UITextView) {
        // This function is called as a result of tapping the back button and resigning first responder
        // Only confirm changes if the custom return button was tapped
        if isCancelling { return }

        viewModel.confirm()
        _ = navigationController?.popViewController(animated: true)
    }

    // MARK: Actions

    @objc private func backButtonTapped() {
        isCancelling = true

        if viewModel.changesWereMade {
            let alertViewModel = viewModel.cancelChangesAlertViewModel { [weak self] dismissView in
                guard let welf = self else { return }
                if dismissView {
                    welf.navigationController?.popViewController(animated: true)
                } else {
                    welf.isCancelling = false
                }
            }
            let alert = UIAlertController(viewModel: alertViewModel)
            present(alert, animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func deleteButtonTapped() {
        let alertViewModel = viewModel.deleteAlertViewModel { [weak self] shouldDismissView in
            guard let welf = self else { return }
            if shouldDismissView {
                welf.viewModel.notes.value = nil
                welf.navigationController?.popViewController(animated: true)
            }
        }
        let alert = UIAlertController(viewModel: alertViewModel)
        present(alert, animated: true, completion: nil)
    }
}

extension MealEventDetailsTitleView {
    fileprivate func configure(with viewModel: MealEventNotesEntryViewModel) {
        leadingFlushConstraint.priority = 999.layoutPriority
        leadingPaddingConstraint.priority = 1.layoutPriority
        trailingSuperviewConstraint.priority = 999.layoutPriority
        trailingArrowConstraint.priority = 1.layoutPriority

        arrowView.isHidden = true
        backgroundView.isHidden = true

        titleLabel.font = UIFont.openSansSemiboldFont(size: 16)
        titleLabel.text = "Meal Notes"
        subtitleLabel.text = viewModel.mealName

        updateSize()
    }
}
