//
//  CreateMealViewController.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/16/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import Intrepid

class CreateMealViewController: UIViewController, CreateMealChildViewControllerDelegate, SegmentedSliderDelegate {
    private struct Constants {
        static var containerScrollViewTopSpace: CGFloat {
            if UIDevice.current.screenType == .notch {
                return -80
            } else if UIDevice.current.isRunningiOS10 {
                return -1
            } else {
                return -65
            }
        }
    }

    let viewModel: CreateMealViewModel

    var backgroundView: GradientView?
    @IBOutlet weak var containerScrollView: UIScrollView!
    @IBOutlet weak var segmentedSlider: SegmentedSlider!
    @IBOutlet weak var containerScrollViewTopSpaceConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    init(viewModel: CreateMealViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItem()
        setupBackgroundGradient()
        setupSegmentedSlider()
        setupChildViewControllers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }

    override func viewDidLayoutSubviews() {
        backgroundView?.setNeedsDisplay()
        layoutChildViews()
        refreshSegmentedSliderCornerRadius()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        navigationBar.barStyle = .black
        navigationBar.tintColor = .white
        containerScrollViewTopSpaceConstraint.constant = Constants.containerScrollViewTopSpace
    }

    private func setupNavigationItem() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "xButton"), style: .plain, target: self, action: #selector(closeButtonTapped(_:)))
    }

    private func setupBackgroundGradient() {
        let colors = [
            UIColor.piCommonMealGradientStartColor,
            UIColor.piCommonMealGradientFinishColor
        ]

        let backgroundView = GradientView(colors: colors, direction: .vertical)
        backgroundView.frame = view.bounds
        view.insertSubview(backgroundView, at: 0)
        view.constrainView(toAllEdges: backgroundView)

        self.backgroundView = backgroundView
    }

    private func setupSegmentedSlider() {
        segmentedSlider.delegate = self
        segmentedSlider.items = viewModel.childTitles
        segmentedSlider.segmentLayoutInverted = true
        segmentedSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))

        segmentedSlider.backgroundSegmentView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        segmentedSlider.selectedSegmentView.backgroundColor = UIColor.white
        segmentedSlider.segmentLabelFont = UIFont.openSansSemiboldFont(size: 16.0)
        segmentedSlider.segmentLabelTextColor = UIColor.piTestMealTableCellIndicatorColor

        segmentedSlider.addTarget(self, action: #selector(segmentValueChanged), for: .valueChanged)
    }

    private func setupChildViewControllers() {
        let childViewControllers = viewModel.childViewModels.map { $0.viewController }
        childViewControllers.forEach {
            ip_addChildViewController($0, to: containerScrollView)
            $0.delegate = self
        }
    }

    private func layoutChildViews() {
        let childViews = children.map { $0.view }
        for (index, view) in childViews.enumerated() {
            view?.frame = containerScrollView.frame.offsetBy(dx: 0, dy: CGFloat(index) * containerScrollView.frame.height)
        }
        containerScrollView.contentSize = CGSize(width: containerScrollView.bounds.width, height: containerScrollView.bounds.height * CGFloat(childViews.count))
    }

    private func refreshSegmentedSliderCornerRadius() {
        let backgroundSegmentLayer = segmentedSlider.backgroundSegmentView.layer
        backgroundSegmentLayer.cornerRadius = backgroundSegmentLayer.bounds.height / 2

        let selectedSegmentLayer = segmentedSlider.selectedSegmentView.layer
        selectedSegmentLayer.cornerRadius = selectedSegmentLayer.bounds.height / 2
    }

    // MARK: - Child View Controller Selection

    private func selectChildViewController(at index: Int, animated: Bool = false) {
        let contentOffset = CGPoint(x: 0, y: CGFloat(index) * containerScrollView.frame.height)
        containerScrollView.setContentOffset(contentOffset, animated: animated)
        segmentedSlider.selectItem(at: index, animated: animated)
        view.endEditing(true)
    }

    // MARK: - Actions

    @objc func segmentValueChanged(_ sender: SegmentedSlider) {
        selectChildViewController(at: sender.selectedSegmentIndex, animated: true)
    }

    @objc func closeButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - CreateMealChildViewControllerDelegate

    func childViewControllerDidSelectNextStep(_ viewController: CreateMealChildViewController) {
        guard let currentIndex = children.firstIndex(of: viewController) else { return }
        if viewController == children.last {
            // Save meal
            viewModel.createMeal { [weak self] result in
                switch result {
                case .synchronized, .localOnly:
                    self?.dismiss(animated: true, completion: nil)
                default:
                    break
                }
                
                guard let alertMessage = result.alertMessage() else { return }
                let alert = UIAlertController.errorAlertController(withMessage: alertMessage)
                self?.present(alert, animated: true, completion: nil)
            }
        } else {
            // Scroll to next step
            let nextIndex = currentIndex + 1
            selectChildViewController(at: nextIndex, animated: true)
        }
    }

    func childViewControllerDidSelectPreviousStep(_ viewController: CreateMealChildViewController) {
        guard
            let currentIndex = children.firstIndex(of: viewController),
            currentIndex > 0
        else { return }

        let previousIndex = currentIndex - 1
        selectChildViewController(at: previousIndex, animated: true)
    }

    // MARK: - SegmentedSliderDelegate

    func segmentedSlider(_ segmentedSlider: SegmentedSlider, canSelectSegment index: Int) -> Bool {
        return viewModel.canSelectSegment(at: index, currentIndex: segmentedSlider.selectedSegmentIndex)
    }
}

extension SaveResult {
    fileprivate func alertMessage() -> String? {
        switch self {
        case .synchronized, .localOnly:
            return nil
        case .failure(let error):
            switch error {
            case APIClientError.httpError(_, _, let data):
                guard let errorReason = PilotAPIErrorReason.reasons(for: data).first else { break }
                return errorReason.displayMessage
            case MealSaveError.nameExists:
                return "A meal with this name already exists"
            default:
                break
            }
        default:
            break
        }

        return "We're sorry, but we were unable to log your meal. Contact your study coordinator for assistance."
    }
}
