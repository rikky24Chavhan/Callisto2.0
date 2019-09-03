//
//  LoginFormViewController.swift
//  MealTrackingPilot
//
//  Created by Steve Galbraith on 7/16/18.
//  Copyright © 2018 Intrepid. All rights reserved.
//

import UIKit
import RxSwift
import Intrepid

class LoginFormViewController: UIViewController, UITextFieldDelegate {

    private struct Constants {
        static let userIDPlaceholderXDifference: CGFloat = 7
        static let placeholderYDifference: CGFloat = 25
        static let passwordPlaceholderXDifference: CGFloat = 10
        static let smallScreenUserIDLabelYOrigin: CGFloat = 296
        static let smallScreenPasswordLabelYOrigin: CGFloat = 374
    }

    fileprivate enum LabelToggleState {
        case setup
        case entering
        case exiting
    }

    // MARK: - Properties

    @IBOutlet private weak var signInButton: UIButton!
    @IBOutlet weak var userIDTextField: EditIconTextField!
    @IBOutlet weak var passwordTextField: EditIconTextField!
    @IBOutlet weak var backgroundGradientView: GradientView!
    @IBOutlet weak var messageBubbleShadowView: UIView!
    @IBOutlet weak var messageBubbleLabel: UILabel!
    @IBOutlet weak var messageBubbleView: RoundedCornerView!
    @IBOutlet weak var userIDPlaceholderLabel: UILabel!
    @IBOutlet weak var passwordPlaceholderLabel: UILabel!

    var viewModel: LoginFormViewModel
    var userNamePlaceholderCenterPoint = CGPoint.zero
    var passwordPlaceholderCenterPoint = CGPoint.zero
    
    private let bag = DisposeBag()

    // MARK: - Lifecycle

    init(viewModel: LoginFormViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        userIDTextField.text = viewModel.userID.value
        passwordTextField.text = viewModel.password.value

        setupBackgroundGradient()
        setupMessageBubble()
        setupSignInButton()
        setupBackground()
        setupObservers()
        setupTextFieldLabels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeKeyboard()
        setupTextFieldLabels()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unsubscribeKeyboard()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Actions

    @IBAction func signInButtonTapped(_ sender: UIButton) {
        // TODO: authenticate with backend, for now we will just dismiss the view
        [userIDTextField, passwordTextField].forEach { textField in
            textField?.resignFirstResponder()
        }
        viewModel.login()
    }
    

    // MARK: Setup

    private func setupBackgroundGradient() {
        let colors = [
            UIColor.piCornflower,
            UIColor.piCornflowerTwo,
            UIColor.piSkyBlue,
            ]
        
        backgroundGradientView?.direction = .vertical
        backgroundGradientView?.colors = colors
    }

    private func setupMessageBubble() {
        messageBubbleView.backgroundColor = viewModel.backgroundColor
        messageBubbleView.cornerRadius = 20
        messageBubbleView.roundedCorners = [.topLeft, .topRight, .bottomRight]
        
        let shadowLayer = messageBubbleShadowView.layer
        shadowLayer.shadowColor = UIColor.piDenim.cgColor
        shadowLayer.shadowOpacity = 0.2
        shadowLayer.shadowRadius = 6.0
        shadowLayer.shadowOffset = CGSize(width: 0, height: 2)

        messageBubbleLabel.text = viewModel.helpText
    }

    private func setupSignInButton() {
        signInButton.layer.cornerRadius = 32
        signInButton.layer.masksToBounds = true
    }

    private func setupBackground() {
        let colors: [UIColor] = [
            UIColor.piCornflower,
            UIColor.piBackgroundBlue
        ]
        let backgroundView = GradientView(colors: colors, locations: nil, direction: .vertical)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        view.sendSubviewToBack(backgroundView)
        
        view.constrainView(toAllEdges: backgroundView)
    }

    private func setupObservers() {
        viewModel.userID <- userIDTextField.rx.text >>> bag
        viewModel.password <- passwordTextField.rx.text >>> bag
        viewModel.status.subscribe(onNext: { [weak self] (_) in
            guard let welf = self else { return }

            Main {
                welf.messageBubbleLabel.text = welf.viewModel.helpText
                welf.messageBubbleView.backgroundColor = welf.viewModel.backgroundColor
            }
        }) >>> bag
    }

    private func setupTextFieldLabels() {
        let screenWidth = UIScreen.main.bounds.width

        [userIDTextField, passwordTextField].forEach { textField in
            guard let textField = textField else { return }

            // On small screened phones we need to tell it where the labels will be since they don't use autolayout
            if screenWidth < 375 {
                let label = getLabel(for: textField)
                let updatedYOrigin = textField == userIDTextField ? Constants.smallScreenUserIDLabelYOrigin : Constants.smallScreenPasswordLabelYOrigin
                label.translatesAutoresizingMaskIntoConstraints = true
                label.frame.origin.y = updatedYOrigin
            }

            if !(textField.text ?? "").isEmpty {
                updateLabelLocation(for: textField, withState: .setup)
            }
        }
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        updateLabelLocation(for: textField, withState: .entering)
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // Prevents text from jumping around when done editings
        textField.resignFirstResponder()
        textField.layoutIfNeeded()

        if textField.text?.isEmpty ?? false {
            updateLabelLocation(for: textField, withState: .exiting)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == userIDTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return false
    }

    // MARK: Keyboard

    private func subscribeKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func unsubscribeKeyboard() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private dynamic func keyboardWillShow(_ notification: Notification) {
        guard
            let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.size.height,
            self.view.frame.origin.y == 0
            else { return }

        self.view.frame.origin.y -= (keyboardHeight - 50)
    }

    @objc private dynamic func keyboardWillHide(_ notification: Notification) {
        guard self.view.frame.origin.y < 0 else { return }

        self.view.frame.origin.y = 0
    }

    // MARK: - Helpers

    private func updateLabelLocation(for textField: UITextField, withState state: LabelToggleState) {
        let placeholderLabel = getLabel(for: textField)

        // If there is already a value in the text field, we don't need to move the label up unless setting up
        if state != .setup && !(textField.text ?? "").isEmpty {
            return
        }

        let multiplier: CGFloat = state == .entering ? 1.0 : -1.0
        let scale: CGFloat = state == .exiting ? 1.0 : 0.75
        let horizontalDifference = placeholderLabel == passwordPlaceholderLabel ? Constants.passwordPlaceholderXDifference : Constants.userIDPlaceholderXDifference
        let newYOrigin = placeholderLabel.frame.origin.y - (Constants.placeholderYDifference * multiplier)
        let newXOrigin = placeholderLabel.frame.origin.x - (horizontalDifference * multiplier)

        if state != .setup {
            UIView.animate(withDuration: 0.4, animations: {
                placeholderLabel.frame.origin = CGPoint(x: newXOrigin, y: newYOrigin)
                placeholderLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
                placeholderLabel.updateConstraints()
            }, completion: { _ in
                let yOriginBuffer: CGFloat = state == .exiting ? 3 : Constants.placeholderYDifference
                placeholderLabel.translatesAutoresizingMaskIntoConstraints = true
                placeholderLabel.frame.origin = CGPoint(x: textField.frame.origin.x, y: textField.frame.minY - yOriginBuffer)
            })
        } else {
            var yOriginBuffer: CGFloat = state == .exiting ? 3 : Constants.placeholderYDifference
            if UIScreen.main.bounds.width < 375 {
                yOriginBuffer *= 2.5 // on smaller screens the original position is low, so we need to increase the vertical buffer
            }
            placeholderLabel.translatesAutoresizingMaskIntoConstraints = true
            placeholderLabel.frame.origin = CGPoint(x: textField.frame.origin.x, y: textField.frame.minY - yOriginBuffer)
            placeholderLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
            placeholderLabel.updateConstraints()
        }
    }

    private func getLabel(for textField: UITextField) -> UILabel {
        var label: UILabel

        if textField == userIDTextField {
            label = userIDPlaceholderLabel
        } else {
            label = passwordPlaceholderLabel
        }

        return label
    }
}
