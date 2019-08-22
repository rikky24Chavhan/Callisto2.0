//
//  DatePickerViewController.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/30/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import SwiftDate

protocol DatePickerViewControllerDelegate: class {
    func datePickerViewControllerDidCancel(_ viewController: DatePickerViewController)
    func datePickerViewController(_ viewController: DatePickerViewController, didSelect date: Date)
}

public final class DatePickerViewController: UIViewController {
    private struct Constants {
        static let buttonTopSpace: CGFloat = UIDevice.current.isRunningiOS10 ? 22 : 0
        static let viewTopSpace: CGFloat = UIDevice.current.isRunningiOS10 ? 66 : 43
    }

    // MARK: - Properties

    weak var delegate: DatePickerViewControllerDelegate?

    private var passedInDate: Date

    @IBOutlet private weak var bubbleShadowView: UIView!
    @IBOutlet private weak var bubbleView: RoundedCornerView!
    @IBOutlet private weak var datePicker: UIDatePicker!
    @IBOutlet weak var buttonTopSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewTopSpaceConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError()
    }

    init(date: Date) {
        self.passedInDate = date
        super.init(nibName: nil, bundle: nil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupBubbleView()
        setupDatePicker()
    }

    // MARK: - Setup

    private func setupNavigation() {
        buttonTopSpaceConstraint.constant = Constants.buttonTopSpace
        viewTopSpaceConstraint.constant = Constants.viewTopSpace
    }

    private func setupBubbleView() {
        bubbleView.roundedCorners = [.topLeft, .topRight, .bottomRight]

        let shadowLayer = bubbleShadowView.layer
        shadowLayer.shadowColor = UIColor.piDenim.cgColor
        shadowLayer.shadowOpacity = 0.025
        shadowLayer.shadowRadius = 4.0
        shadowLayer.shadowOffset = CGSize(width: 0, height: 2)
    }

    private func setupDatePicker() {
        datePicker.date = passedInDate
        datePicker.minimumDate = passedInDate - 2.days
        datePicker.maximumDate = passedInDate + 4.hours
    }

    // MARK: - Actions

    @IBAction private func cancelButtonTapped() {
        delegate?.datePickerViewControllerDidCancel(self)
    }

    @IBAction private func setButtonTapped() {
        delegate?.datePickerViewController(self, didSelect: datePicker.date)
    }
}
