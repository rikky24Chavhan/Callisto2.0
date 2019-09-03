//
//  CreateMealNameViewController.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/20/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import RxSwift
import Intrepid

final class CreateMealNameViewController: CreateMealChildViewController {

    let viewModel: CreateMealNameViewModel

    private let bag = DisposeBag()

    override var indicatorAlignmentViews: [UIView] {
        return [
            nameTextField
        ]
    }

    @IBOutlet weak var nameTextField: EditIconTextField!

    // MARK: - Lifecycle

    init(viewModel: CreateMealNameViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNameTextField()
        setupObservers()
    }

    // MARK: - Setup

    private func setupNameTextField() {
        configureTextField(nameTextField, withPlaceholder: "Meal Name")
        nameTextField.font = UIFont.openSansSemiboldFont(size: 42.0)
        nameTextField.minimumFontSize = 20.0
        nameTextField.adjustsFontSizeToFitWidth = true
        nameTextField.returnKeyType = .next
        nameTextField.enablesReturnKeyAutomatically = true
        nameTextField.addTarget(self, action: #selector(navigateToNextStep), for: .editingDidEndOnExit)
    }

    private func setupObservers() {
        viewModel.name <- nameTextField.rx.text >>> bag
        nameTextField.rx.text <- viewModel.validatedName >>> bag

        viewModel.nextNavigationEnabled.subscribe(onNext: nextNavigationEnabledSubscribeHandler) >>> bag
        viewModel.indicatorPosition.subscribe(onNext: indicatorPositionSubscribeHandler) >>> bag
    }
}
