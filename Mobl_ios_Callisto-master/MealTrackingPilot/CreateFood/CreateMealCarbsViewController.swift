//
//  CreateMealCarbsViewController.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/23/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import RxSwift
import Intrepid

final class CreateMealCarbsViewController: CreateMealChildViewController {

    let viewModel: CreateMealCarbsViewModel

    private let bag = DisposeBag()

    override var indicatorAlignmentViews: [UIView] {
        return [
            carbsTextField
        ]
    }

    @IBOutlet weak var carbsTextField: EditIconTextField!
    @IBOutlet weak var nextButtonContainerView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK: - Lifecycle

    init(viewModel: CreateMealCarbsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCarbsTextField()
        setupNextButton()
        setupObservers()
    }

    // MARK: - Setup

    private func setupCarbsTextField() {
        configureTextField(carbsTextField, withPlaceholder: "#", placeholderFontSize: 42.0)
        carbsTextField.configureCustomReturnButton()
        carbsTextField.keyboardType = .decimalPad
        carbsTextField.returnKeyType = .done
    }

    private func setupNextButton() {
        nextButton.layer.cornerRadius = 8.0
        nextButton.layer.masksToBounds = true

        nextButtonContainerView.layer.shadowOpacity = 0.1
        nextButtonContainerView.layer.shadowRadius = 4.0
        nextButtonContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    private func setupObservers() {
        carbsTextField.rx.text <-> viewModel.carbsString >>> bag

        activityIndicator.rx.isAnimating <- viewModel.isRequestInProgress >>> bag

        nextSwipeGestureRecognizer?.isEnabled = false   // Disable swipe gesture to complete flow

        viewModel.indicatorPosition.subscribe(onNext: indicatorPositionSubscribeHandler) >>> bag
        viewModel.nextNavigationEnabled.subscribe(onNext: nextNavigationEnabledSubscribeHandler) >>> bag
    }

    // MARK: - Actions

    @IBAction func carbsTextFieldDidEndOnExit(_ sender: UITextField) {
        sender.resignFirstResponder()
    }
}
