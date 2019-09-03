//
//  AppNavigator.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/6/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import Intrepid
import KeychainAccess
import RealmSwift

final class AppNavigator: NSObject, LoginClientDelegate, LoginClientUIDelegate {

    let window: UIWindow?

    let apiClient: PilotAPIClient
    var loginClient: LoginCredentialsLoginClient
    var userProvider: LoginUserProviding
    let onboardingManager: OnboardingManager
    let mealDataController: MealDataController
    let healthKitController: HealthKitController
    let locationController: LocationController

    private let rootNavigationController: UINavigationController = {
        let launchScreenViewController = ViewController()
        return UINavigationController(rootViewController: launchScreenViewController)
    }()

    private lazy var signInViewController: LoginLandingViewController = {
        let controller = LoginLandingViewController.ip_fromNib()
        controller.loginClient = self.loginClient
        return controller
    }()
    var dismissLogin: (() -> Void)?
    private(set) var shouldReload = true

    init(
        window: UIWindow?,
        apiClient: PilotAPIClient,
        loginClient: LoginCredentialsLoginClient,
        userProvider: LoginUserProviding,
        onboardingManager: OnboardingManager,
        mealDataController: MealDataController,
        healthKitController: HealthKitController,
        locationController: LocationController
    ) {
        self.window = window

        self.apiClient = apiClient
        self.loginClient = loginClient
        self.userProvider = userProvider
        self.onboardingManager = onboardingManager
        self.mealDataController = mealDataController
        self.healthKitController = healthKitController
        self.locationController = locationController

        super.init()

        self.loginClient.delegate = self
        self.loginClient.uiDelegate = self
        self.loginClient.login()

        rootNavigationController.delegate = self
    }

    func refreshRootViewController(animated: Bool = true) {
        // If this is on initial launch, we have to give the window a rootViewController immediately
        if window?.rootViewController == nil {
            window?.rootViewController = rootNavigationController
        }
        
        var isSignedIn = (userProvider.user != nil)

        // Detects if user is opening the app after deletion with an expired token.
        if
            let userProvider = userProvider as? PilotLoginClient,
            let user = userProvider.user,
            onboardingManager.shouldOnboardUser(user),
            let accessCredentials = userProvider.accessCredentials,
            let expirationDate = accessCredentials.expirationDate,
            Date() > expirationDate {
            // Log user out to sign back in.
            userProvider.logout()
            isSignedIn = false
        }

        let controller = isSignedIn ? postLoginViewController() : signInViewController
        if shouldReload {
            rootNavigationController.setViewControllers([controller], animated: animated)
        }

        dismissLogin?()
        dismissLogin = nil
    }

    private func postLoginViewController() -> UIViewController {
        guard let user = userProvider.user else {
            print("Error: AppNavigator could not determine the current logged-in user. Logging out.")
            loginClient.logout()
            return signInViewController
        }

        if onboardingManager.shouldOnboardUser(user) {
            return onboardingViewController()
        }  else {
            return dashboardViewController()
        }
    }

    // MARK: - Onboarding

    private func onboardingViewController() -> UIViewController {
        return chatViewController()
    }

    private func chatViewController() -> UIViewController {
        let chatViewModel = ChatViewModel(
            healthKitPermissionsController: healthKitController,
            locationPermissionsController: locationController
        )

        let chatNodeGraph = BasicChatNodeGraph(jsonFileName: "ChatBotGraph")
        let chatDriver = ChatDriver(chatController: chatViewModel, nodeGraph: chatNodeGraph, completion: { [weak self] in
            guard let welf = self else {
                return
            }
            After(0.5) {
                welf.pushToChatCompletionViewController()
            }
        })
        return ChatViewController(viewModel: chatViewModel, chatDriver: chatDriver)
    }

    private func pushToChatCompletionViewController() {
        let chatCompletionViewModel = ChatCompletionViewModel(completion: { [weak self] in
            guard let welf = self else {
                return
            }
            welf.completeOnboarding()
        })
        let chatCompletionViewController = ChatCompletionViewController(viewModel: chatCompletionViewModel)
        rootNavigationController.pushViewController(chatCompletionViewController, animated: true)
    }

    private func completeOnboarding() {
        guard let user = userProvider.user else {
            print("Error: AppNavigator could not determine the current logged-in user. Logging out.")
            loginClient.logout()
            return
        }

        self.onboardingManager.didFinishOnboardingForUser(user)

        After(0.5) {
            self.setShouldReload(true)
            self.refreshRootViewController(animated: true)
        }
    }

    // MARK: - Demo

    private func demoDashboardViewController() -> UIViewController {
        let demoApiClient = DemoPilotAPIClient()
        demoApiClient.accessCredentialsProvider = apiClient.accessCredentialsProvider

        let demoMealDataController = try! RealmMealDataController(
            realmConfiguration: Realm.Configuration(inMemoryIdentifier: "DemoRealm"),
            apiClient: demoApiClient
        )

        let viewModel = DemoDashboardViewModel(
            keychain: Keychain(),
            mealDataController: demoMealDataController,
            userProvider: userProvider,
            loginClient: loginClient,
            action: { [weak self] in
                guard let welf = self else {
                    return
                }
                welf.completeDemo()
        })
        return DashboardViewController(viewModel: viewModel)
    }

    private func completeDemo() {
        guard let user = userProvider.user else {
            print("Error: AppNavigator could not determine the current logged-in user. Logging out.")
            loginClient.logout()
            return
        }

        self.onboardingManager.didFinishPilotDemo(user)

        After(0.5) {
            self.setShouldReload(true)
            self.refreshRootViewController(animated: true)
        }
    }

    // MARK: - Dashboard

    private func dashboardViewController() -> UIViewController {
        let viewModel = DashboardViewModel(
            keychain: Keychain(),
            mealDataController: mealDataController,
            userProvider: userProvider,
            loginClient: loginClient
        )
        return DashboardViewController(viewModel: viewModel)
    }

    // MARK: - LoginClientDelegate

    func loginClient(_ client: LoginClient, didFinishLoginWithResult result: Result<AccessCredentials,Error>) {
        switch result {
        case .failure(let error):
            print("Received sign-in error: \(error)")
        default:
            break
        }

        loginDidChange(animated: false)
    }

    func loginClientDidDisconnect(_ client: LoginClient) {
        mealDataController.reset()
        loginDidChange()
    }

    private func loginDidChange(animated: Bool = true) {
        if userProvider.isLoggedInAsPrimaryUser() {
            locationController.startMonitoring()
        } else {
            locationController.stopMonitoring()
        }
        refreshRootViewController(animated: animated)
    }

    // MARK: - LoginClientUIDelegate

    func presentLoginViewController() {
        // If we are currently on the login landing screen, don't present it again
        guard
            let presentedViewController = rootNavigationController.presentedViewController,
            presentedViewController as? LoginLandingViewController == nil
            else { return }

        // If we are displaying an error on the login form, we do not need to go back to the landing screen
        if let loginFormViewController = rootNavigationController.presentedViewController as? LoginFormViewController, loginFormViewController.viewModel.currentStatus.value != .normal {
            return
        }

        // User token has been revoved and we need to log in again
        let viewController  = LoginLandingViewController()
        viewController.loginClient = loginClient
        viewController.view.layoutIfNeeded()    // This is necessary to avoid an empty screen in some cases
        rootNavigationController.visibleViewController?.present(viewController, animated: true, completion: nil)
    }

    func dismissLoginViewControllers() {
        dismissLogin = {
            if var topController = self.window?.rootViewController {
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                    topController.dismiss(animated: true, completion: nil)
                }
            }
        }
    }

    func displayLoginError(for error: Error) {
        guard let loginFormViewController = window?.rootViewController?.presentedViewController as? LoginFormViewController else { return }

        loginFormViewController.viewModel.setStatus(.error(error))
    }

    func setShouldReload(_ value: Bool) {
        shouldReload = value
    }
}

extension AppNavigator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if fromVC is ChatViewController && toVC is ChatCompletionViewController {
            return ChatToChatCompletionTransitionAnimator()
        }
        return nil
    }
}
