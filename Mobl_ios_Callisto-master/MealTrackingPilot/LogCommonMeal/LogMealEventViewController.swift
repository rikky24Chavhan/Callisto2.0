//
//  LogMealEventViewController.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/17/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import RxSwift

protocol LogMealEventViewControllerDelegate: class {
    func logMealEventViewControllerSaveButtonTapped(_ viewController: LogMealEventViewController, withMeal meal: Meal)
}

public final class LogMealEventViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MealSelectionTableFooterViewDelegate {

    weak var delegate: LogMealEventViewControllerDelegate?

    private struct Constants {
        static let occasionPickerHeight: CGFloat = 90.0
        static let occasionPickerBottomSpace: CGFloat = 14.0
        static let occasionPickerTopSpace: CGFloat = 65.0
        static let defaultRowHeight: CGFloat = 72.0
        static let defaultCopyrightCellHeight: CGFloat = 96.0
        static let defaultAdderCopyrightCellHeight: CGFloat = 168.0
    }

    @IBOutlet weak var backgroundViewContainer: UIView!
    @IBOutlet weak var occasionPicker: OccasionPicker!
    @IBOutlet weak var dosageRecommendationBanner: UIView!
    @IBOutlet weak var mealSelectionTableView: UITableView!
    @IBOutlet weak var nextStepButton: UIButton!

    @IBOutlet var occasionPickerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var occasionPickerBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var occasionPickerTopSpaceConstraint: NSLayoutConstraint!

    fileprivate let viewModel: LogMealEventViewModel

    private let bag = DisposeBag()

    init(viewModel: LogMealEventViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.delegate = self
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()
        setupMealSelectionTableView()

        configureFromViewModel()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupNavigationBar(animated: animated)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToSelectedMeal()
    }

    private func configureFromViewModel() {
        configureBackgroundView(viewModel.backgroundView)
        configureOccasionPicker()
        bindTableDataSource()
        configureNextStepButton()

        viewModel.getMeals(completion: nil)
    }

    private func configureBackgroundView(_ backgroundView: UIView?) {
        guard let backgroundView = backgroundView else {
            return
        }

        backgroundViewContainer.addSubview(backgroundView)
        _ = backgroundViewContainer.constrainView(toAllEdges: backgroundView)
    }

    // MARK: - Navigation Bar

    private func setupNavigationBar(animated: Bool) {
        guard let navigationBar = navigationController?.navigationBar else { return }

        let duration = animated ? 0.3 : 0.0

        UIView.animate(withDuration: duration) {
            navigationBar.barStyle = .black
            navigationBar.tintColor = .white
            navigationBar.titleTextAttributes = [
                NSAttributedString.Key.font: UIFont.openSansSemiboldFont(size: 17.0)
            ]
        }

        setNeedsStatusBarAppearanceUpdate()
    }

    private func setupNavigationItem() {
        title = viewModel.navigationTitle

        if viewModel.mode == .create {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "xButton"), style: .plain, target: self, action: #selector(closeButtonTapped(_:)))
        }
        navigationItem.backBarButtonItem = UIBarButtonItem.emptyBackItem()
    }

    // MARK: - Actions

    @objc func closeButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func nextStepButtonTapped(_ sender: UIButton) {
        guard let selectedMeal = viewModel.selectedMeal.value else { return }
        delegate?.logMealEventViewControllerSaveButtonTapped(self, withMeal: selectedMeal)
    }

    // MARK: - Completion

    private func configureNextStepButton() {
        nextStepButton.setTitle(viewModel.nextButtonTitle, for: .normal)
        viewModel.nextStepButtonEnabled
            .bind(to: nextStepButton.rx.isEnabled)
            .disposed(by: bag)
    }

    private func goToNextStep() {
        guard let mealEventDetailsViewModel = viewModel.mealEventDetailsViewModel() else { return }
        let mealDetailsController = MealEventDetailsViewController(viewModel: mealEventDetailsViewModel)
        navigationController?.pushViewController(mealDetailsController, animated: true)
    }

    // MARK: - Occasion Picker

    private func configureOccasionPicker() {
        let pickerViewModel = viewModel.pickerViewModel
        occasionPicker.scrollingDirection = .horizontal
        occasionPicker.scrollingStyle = .infinite
        occasionPicker.dataSource = pickerViewModel
        occasionPicker.delegate = pickerViewModel
        occasionPicker.selectItem(pickerViewModel.selectedIndex.value, animated: false)

        occasionPickerHeightConstraint.constant = viewModel.isOccasionPickerHidden ? 0 : Constants.occasionPickerHeight
        occasionPickerBottomSpaceConstraint.constant = viewModel.isOccasionPickerHidden ? 0 : Constants.occasionPickerBottomSpace

        // UI hack for phones running iOS 10 becuse it does not support safe area
        if UIDevice.current.isRunningiOS10 {
            occasionPickerTopSpaceConstraint.constant = Constants.occasionPickerTopSpace
        }
    }

    // MARK: - Meal Selection Table

    private func bindTableDataSource() {
        viewModel.mealSelectionCellViewModelsObservable.subscribe(onNext: { [weak self] cellViewModels in
            self?.mealSelectionTableView.reloadData()
        }).disposed(by: bag)
    }

    private func setupMealSelectionTableView() {
        mealSelectionTableView.dataSource = self
        mealSelectionTableView.delegate = self

        mealSelectionTableView.estimatedRowHeight = MealSelectionCell.minimumHeight
        mealSelectionTableView.rowHeight = UITableView.automaticDimension

        MealSelectionCell.registerNib(mealSelectionTableView)
        mealSelectionTableView.register(CopyrightTableViewCell.nib, forCellReuseIdentifier: CopyrightTableViewCell.identifier)
    }

    private func scrollToSelectedMeal() {
        guard let selectedIndexPath = viewModel.selectedIndexPath else { return }
        mealSelectionTableView.scrollToRow(at: selectedIndexPath, at: .middle, animated: true)
    }

    // MARK: UITableViewDataSource

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section > 0 ? 1 : viewModel.mealSelectionCellViewModels.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CopyrightTableViewCell.identifier, for: indexPath) as! CopyrightTableViewCell
            cell.selectionStyle = .none

            if viewModel.allowsAddNewMeal {
                let addNewMealView = MealSelectionTableFooterView.fromNib()
                addNewMealView.delegate = self
                cell.configure(with: addNewMealView)
            }

            return cell
        } else {
            let cellViewModel = viewModel.mealSelectionCellViewModels[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: MealSelectionCell.cellIdentifier, for: indexPath)

            if let mealSelectionCell = cell as? MealSelectionCell {
                mealSelectionCell.viewModel = cellViewModel
            }

            return cell
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section > 0 {
            let totalMealOptionsHeight = Constants.defaultRowHeight * CGFloat(viewModel.mealSelectionCellViewModels.count)
            let proposedHeight = tableView.frame.height - totalMealOptionsHeight
            let defaultCellHeight = viewModel.allowsAddNewMeal ? Constants.defaultAdderCopyrightCellHeight : Constants.defaultCopyrightCellHeight

            return proposedHeight > defaultCellHeight ? proposedHeight : defaultCellHeight
        } else {
            return Constants.defaultRowHeight
        }
    }

    // MARK: UITableViewDelegate

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didToggleSelectionForMeal(at: indexPath)
    }

    // MARK: MealSelectionTableFooterViewDelegate

    public func mealSelectionTableFooterDidSelectAddNewMeal(_ footerView: MealSelectionTableFooterView) {
        presentCreateMealViewController()
    }

    private func presentCreateMealViewController() {
        let createMealViewModel = viewModel.createMealViewModel
        let createMealViewController = CreateMealViewController(viewModel: createMealViewModel)
        let navigationController = UINavigationController(rootViewController: createMealViewController)
        present(navigationController, animated: true, completion: nil)
    }
}

extension LogMealEventViewController: LogMealEventViewControllerDelegate {
    func logMealEventViewControllerSaveButtonTapped(_ viewController: LogMealEventViewController, withMeal meal: Meal) {
        guard let mealEventDetailsViewModel = viewModel.mealEventDetailsViewModel() else { return }
        let mealDetailsController = MealEventDetailsViewController(viewModel: mealEventDetailsViewModel)
        navigationController?.pushViewController(mealDetailsController, animated: true)
    }
}
