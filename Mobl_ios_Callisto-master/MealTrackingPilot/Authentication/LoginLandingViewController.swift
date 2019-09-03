//
//  LoginLandingViewController.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/6/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

final class LoginLandingViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet private weak var logoView: UIImageView!
    @IBOutlet private weak var signInButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!

    var loginClient: LoginCredentialsLoginClient?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLogo()
        setupTitleLabel()
        setupSignInButton()
        setupBackground()
    }

    // MARK: - Actions

    @IBAction dynamic private func signIn() {
        if !PolicyStorage.hasUserAgreed(to: .privacy) {
            let privacyStatementViewController = StatementViewController(ofType: .privacy)
            privacyStatementViewController.agreementCompletion = { [weak self] in
                self?.showTermsOfUse()
            }
            present(privacyStatementViewController, animated: true, completion: nil)
        } else if !PolicyStorage.hasUserAgreed(to: .termsOfUse) {
            let termsOfUseStatementViewController = StatementViewController(ofType: .termsOfUse)
            termsOfUseStatementViewController.agreementCompletion = { [weak self] in
                self?.showLoginForm()
            }
            present(termsOfUseStatementViewController, animated: true, completion: nil)
        } else {
            showLoginForm()
        }
    }

    // MARK: Setup

    private func setupLogo() {
        logoView.image = UIDevice.current.isSmallHeight ? #imageLiteral(resourceName: "logoSmall") : #imageLiteral(resourceName: "logoLarge")
    }

    private func setupTitleLabel() {
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont.openSansSemiboldFont(size: 40),
            NSAttributedString.Key.kern: 10
        ]
        let attributedTitle = NSMutableAttributedString(string: "CALLISTO", attributes: attributes)
        titleLabel.attributedText = attributedTitle
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

    // MARK: - Helper

    private func showLoginForm() {
        guard let loginClient = loginClient else { return }

        let userCredentialStorage = PilotUserLoginCredentialsStorage()
        let viewModel = LoginFormViewModel(loginClient: loginClient, userCredentialStorage: userCredentialStorage)
        let loginViewController = LoginFormViewController(viewModel: viewModel)
        present(loginViewController, animated: true, completion: nil)
    }

    private func showTermsOfUse() {
        let termsOfUseViewController = StatementViewController(ofType: .termsOfUse)
        termsOfUseViewController.agreementCompletion = { [weak self] in
            self?.showLoginForm()
        }
        present(termsOfUseViewController, animated: true, completion: nil)
    }
}
