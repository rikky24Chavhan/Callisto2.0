//
//  CreateMealOccasionsViewController.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/23/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import RxSwift
import Intrepid

final class CreateMealOccasionsViewController: CreateMealChildViewController, UITableViewDataSource, UITableViewDelegate {

    private struct Constants {
        static let occasionTableViewCellIdentifier = "OccasionTableViewCell"
        static let occasionTableViewRowHeight: CGFloat = 52.0
    }

    let viewModel: CreateMealOccasionsViewModel

    private let bag = DisposeBag()

    override var indicatorAlignmentViews: [UIView] {
        return [
            occasionsHeaderLabel
        ]
    }

    @IBOutlet weak var occasionsHeaderLabel: UILabel!
    @IBOutlet weak var occasionsTableView: UITableView!

    // MARK: - Lifecycle

    init(viewModel: CreateMealOccasionsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupOccasionsTableView()
        setupObservers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshTableViewScrollEnabled()
    }

    // MARK: - Setup

    private func setupOccasionsTableView() {
        occasionsTableView.dataSource = self
        occasionsTableView.delegate = self
        occasionsTableView.backgroundColor = UIColor.clear
        occasionsTableView.separatorStyle = .none
        occasionsTableView.rowHeight = Constants.occasionTableViewRowHeight
        occasionsTableView.allowsMultipleSelection = true
        occasionsTableView.register(
            UINib(nibName: CheckmarkTableViewCell.ip_nibName, bundle: nil),
            forCellReuseIdentifier: Constants.occasionTableViewCellIdentifier
        )
    }

    private func setupObservers() {
        viewModel.nextNavigationEnabled.subscribe(onNext: nextNavigationEnabledSubscribeHandler) >>> bag
        viewModel.indicatorPosition.subscribe(onNext: indicatorPositionSubscribeHandler) >>> bag
    }

    private func refreshTableViewScrollEnabled() {
        occasionsTableView.isScrollEnabled = occasionsTableView.contentSize.height > occasionsTableView.bounds.height
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfOccasionRows(for: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.occasionTableViewCellIdentifier, for: indexPath) as! CheckmarkTableViewCell
        cell.configure(viewModel: viewModel.occasionTableViewCellViewModel(for: indexPath))
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectOccasion(at: indexPath)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        viewModel.deselectOccasion(at: indexPath)
    }
}
