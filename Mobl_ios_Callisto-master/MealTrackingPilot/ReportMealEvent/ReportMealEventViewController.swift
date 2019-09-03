//
//  ReportMealEventViewController.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 5/25/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import RxSwift
import Intrepid

class ReportMealEventViewController: UIViewController {

    @IBOutlet weak var mealNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    let viewModel: ReportMealEventViewModel

    private let bag = DisposeBag()

    // MARK: - Init

    init(viewModel: ReportMealEventViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupReportButton()
        setupBindings()
    }

    // MARK: - Setup

    private func setupReportButton() {
        reportButton.layer.cornerRadius = reportButton.bounds.size.height / 2
        reportButton.layer.shadowColor = UIColor.piDenim.cgColor
        reportButton.layer.shadowOpacity = 0.25
        reportButton.layer.shadowRadius = 4.0
        reportButton.layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    // MARK: - Rx

    private func setupBindings() {
        mealNameLabel.rx.text <- viewModel.mealName >>> bag
        dateLabel.rx.text <- viewModel.dateString >>> bag
        activityIndicator.rx.isAnimating <- viewModel.isRequestInProgress >>> bag
        reportButton.rx.isEnabled <- viewModel.isRequestInProgress.asObservable().map { !$0 } >>> bag
    }

    // MARK: - Actions

    @IBAction func reportButtonTapped(_ sender: UIButton) {
        viewModel.report { [weak self] result in
            guard let welf = self else { return }

            switch result {
            case .success:
                welf.dismiss(animated: true, completion: nil)
            case .failure:
                let alert = UIAlertController.errorAlertController(withMessage: "Something went wrong, please try again")
                welf.present(alert, animated: true, completion: nil)
            }
        }
    }

    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
