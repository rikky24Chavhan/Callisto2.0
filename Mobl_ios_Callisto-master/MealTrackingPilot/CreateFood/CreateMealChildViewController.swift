//
//  CreateMealChildViewController.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/20/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

protocol CreateMealChildViewControllerDelegate: class {
    func childViewControllerDidSelectNextStep(_ viewController: CreateMealChildViewController)
    func childViewControllerDidSelectPreviousStep(_ viewController: CreateMealChildViewController)
}

class CreateMealChildViewController: UIViewController {

    private struct Constants {
        static let indicatorDimension: CGFloat = 11.0
        static let indicatorRightMargin: CGFloat = -14.0
    }

    weak var delegate: CreateMealChildViewControllerDelegate?

    var nextSwipeGestureRecognizer: UISwipeGestureRecognizer?
    var previousSwipeGestureRecognizer: UISwipeGestureRecognizer?

    let indicatorView = PulsingIndicatorView(frame: CGRect(x: 0, y: 0, width: Constants.indicatorDimension, height: Constants.indicatorDimension))
    var indicatorViewYConstraint: NSLayoutConstraint?

    var indicatorAlignmentViews: [UIView] {
        fatalError("Subclasses must override")
    }

    lazy var indicatorPositionSubscribeHandler: (Int?) -> Void = { [weak self] position in
        guard
            let position = position,
            let alignmentView = self?.indicatorAlignmentViews[position],
            let didLayout = self?.didLayout
            else {
                self?.indicatorView.isHidden = true
                return
        }

        self?.indicatorView.isHidden = false

        // Animate indicator if view layout has already been performed
        // We don't want the initial layout to be animated
        self?.alignIndicator(with: alignmentView, animated: didLayout)
    }

    lazy var nextNavigationEnabledSubscribeHandler: (Bool) -> Void = { [weak self] enabled in
        self?.nextNavigationEnabled = enabled
        self?.nextButton.isHidden = !enabled
        self?.nextSwipeGestureRecognizer?.isEnabled = enabled
    }

    var nextNavigationEnabled: Bool = false
    private var didLayout = false

    @IBOutlet weak var nextButton: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        setupIndicatorView()
        setupSwipeGestureRecognizers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        indicatorView.startPulsing()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        indicatorView.stopPulsing()
    }

    override func viewDidLayoutSubviews() {
        didLayout = true
    }

    // MARK: - Setup

    private func setupIndicatorView() {
        indicatorView.color = UIColor.white
        view.addSubview(indicatorView)
        _ = indicatorView.constrainView(indicatorView, toWidth: Constants.indicatorDimension)
        _ = indicatorView.constrainView(indicatorView, toHeight: Constants.indicatorDimension)
        _ = view.constrainView(toRight: indicatorView, withInset: Constants.indicatorRightMargin)
    }

    private func setupSwipeGestureRecognizers() {
        let nextSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(nextSwipeGestureRecognized))
        nextSwipeGestureRecognizer.direction = .up
        view.addGestureRecognizer(nextSwipeGestureRecognizer)
        self.nextSwipeGestureRecognizer = nextSwipeGestureRecognizer

        let previousSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(previousSwipeGestureRecognized))
        previousSwipeGestureRecognizer.direction = .down
        view.addGestureRecognizer(previousSwipeGestureRecognizer)
        self.previousSwipeGestureRecognizer = previousSwipeGestureRecognizer
    }

    // MARK: - Position Indicator

    func alignIndicator(with alignmentView: UIView, animated: Bool = false) {
        if let oldYConstraint = indicatorViewYConstraint {
            view.removeConstraint(oldYConstraint)
        }
        indicatorViewYConstraint = view.constrainView(indicatorView, attribute: .centerY, to: alignmentView, attribute: .centerY)

        if animated {
            UIView.animate(withDuration: 0.2, animations: view.layoutIfNeeded)
        } else {
            view.layoutIfNeeded()
        }
    }

    // MARK: - Actions

    @objc private func nextSwipeGestureRecognized(sender: UISwipeGestureRecognizer) {
        navigateToNextStep()
    }

    @objc private func previousSwipeGestureRecognized(sender: UISwipeGestureRecognizer) {
        delegate?.childViewControllerDidSelectPreviousStep(self)
    }

    @IBAction func nextButtonTapped(_ sender: UIButton) {
        navigateToNextStep()
    }

    @objc func navigateToNextStep() {
        delegate?.childViewControllerDidSelectNextStep(self)
    }

    // MARK: - Shared Configuration

    func configureTextField(_ textField: EditIconTextField, withPlaceholder placeholder: String, placeholderFontSize: Float = 32.0) {
        let attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                NSAttributedString.Key.font : UIFont.openSansItalicFont(size: placeholderFontSize),
                NSAttributedString.Key.foregroundColor : UIColor.white.withAlphaComponent(0.5)
            ]
        )
        textField.attributedPlaceholder = attributedPlaceholder
        textField.lineColor = UIColor.white.withAlphaComponent(0.4)
        textField.lineWidth = 2.0
        textField.tintColor = UIColor.white
        textField.iconImage = #imageLiteral(resourceName: "editIconLight")
        textField.autocapitalizationType = .words
    }
}
