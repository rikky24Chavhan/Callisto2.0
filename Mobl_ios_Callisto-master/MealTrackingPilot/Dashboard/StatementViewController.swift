//
//  StatementViewController.swift
//  MealTrackingPilot
//
//  Created by Steve Galbraith on 8/9/18.
//  Copyright © 2018 Intrepid. All rights reserved.
//

import UIKit
import WebKit

enum StatementType: String {
    case privacy = "Privacy Statement"
    case termsOfUse = "Terms of Use"

    static var allValues: [StatementType] {
        return [.privacy, .termsOfUse]
    }

    var textFileName: String {
        switch self {
        case .privacy:
            return "PrivacyStatement"
        case .termsOfUse:
            return "TermsOfUseStatement"
        }
    }

    var webViewHeightAdjustment: CGFloat {
        // Small screen devices on iOS10 need to be adjusted for a webView that is too wide
        switch self {
        case .privacy:
            return UIDevice.current.isRunningiOS10 && UIDevice.current.isSmall ? 429 : 0
        case .termsOfUse:
            return UIDevice.current.isRunningiOS10 && UIDevice.current.isSmall ? 628 : 0
        }
    }
}

struct PolicyStorage {
    private static let defaults = UserDefaults.standard
    private static let defaultPrivacyStatementStorageKey = "hasAgreedToPrivacyStatement"
    private static let defaultTermsOfUseStatementStorageKey = "hasAgreedToTermsOfUse"

    static func hasUserAgreed(to statementType: StatementType) -> Bool {
        switch statementType {
        case .privacy:
            return defaults.bool(forKey: defaultPrivacyStatementStorageKey)
        case .termsOfUse:
            return defaults.bool(forKey: defaultTermsOfUseStatementStorageKey)
        }
    }

    static func setUserHasAgreed(to statementType: StatementType, as value: Bool) {
        switch statementType {
        case .privacy:
            defaults.set(value, forKey: defaultPrivacyStatementStorageKey)
        case .termsOfUse:
            defaults.set(value, forKey: defaultTermsOfUseStatementStorageKey)
        }
    }
}

class StatementViewController: UIViewController, WKNavigationDelegate {

    private struct Constants {
        static let smallDeviceNavigationTopSpace: CGFloat = 19
        static let smallDeviceNavigationBottomSpace: CGFloat = 5
        static let smallDeviceWebViewWidth: CGFloat = 278
        static let exitButtonLeadingSpace: CGFloat = 8
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var agreeButton: UIButton!
    @IBOutlet weak var disagreeButton: UIButton!
    @IBOutlet var webViewContainer: UIView!
    @IBOutlet weak var webViewToScrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var exitButtonToTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelToTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelToUnderlineConstraint: NSLayoutConstraint!
    @IBOutlet weak var exitButtonLeadingConstraint: NSLayoutConstraint!

    // MARK: - Properties

    private let statementType: StatementType
    private let defaults = UserDefaults.standard
    var agreementCompletion: (() -> Void)?

    // MARK: - Lifecycle

    init(ofType type: StatementType, nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil) {
        self.statementType = type
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureFakeNavBar()
        configureWebView()
        configureButtons()
    }

    // MARK: - Configure

    private func configureFakeNavBar() {
        titleLabel.text = statementType.rawValue
        if UIDevice.current.isRunningiOS10 {
            titleLabelToTopConstraint.constant += Constants.smallDeviceNavigationTopSpace
            titleLabelToUnderlineConstraint.constant += Constants.smallDeviceNavigationBottomSpace
            exitButtonToTopConstraint.constant -= Constants.smallDeviceNavigationTopSpace
            exitButtonLeadingConstraint.constant = Constants.exitButtonLeadingSpace
        }
    }

    private func configureButtons() {
        let shouldHideButtons = PolicyStorage.hasUserAgreed(to: statementType)
        agreeButton.isHidden = shouldHideButtons
        disagreeButton.isHidden = shouldHideButtons
        agreeButton.layer.cornerRadius = 25

        // hide buttons until the height of the webview is set
        agreeButton.alpha = 0.0
        disagreeButton.alpha = 0.0

        webViewToScrollViewBottomConstraint.isActive = shouldHideButtons

        exitButton.isHidden = !shouldHideButtons
        let image = #imageLiteral(resourceName: "xButton").withRenderingMode(.alwaysTemplate)
        exitButton.setImage(image, for: .normal)
        exitButton.tintColor = .piDenim
    }

    private func configureWebView() {
        guard
            let htmlFile = Bundle.main.path(forResource: statementType.textFileName, ofType: "html"),
            let htmlString = try? String(contentsOfFile: htmlFile, encoding: .utf8)
            else { return }

        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = self

        webViewContainer.addSubview(webView)
        webViewContainer.constrainView(toAllEdges: webView)
        webView.loadHTMLString(htmlString, baseURL: Bundle.main.bundleURL)
    }

    // MARK: - Actions

    @IBAction func exitButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func agreeButtonTapped() {
        PolicyStorage.setUserHasAgreed(to: statementType, as: true)
        dismiss(animated: true, completion: agreementCompletion)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
         let contentSize = webView.scrollView.contentSize
        webView.frame.size.height = 1
        webView.frame.size = contentSize

        webView.evaluateJavaScript("document.documentElement.scrollHeight") { [weak self] (viewHeight, error) in
            guard
                let welf = self,
                let height = viewHeight as? CGFloat
                else { return }

            let adjustedHeight = height + welf.statementType.webViewHeightAdjustment
            welf.webViewContainer.heightAnchor.constraint(equalToConstant: adjustedHeight).isActive = true

            // Show buttons now that web view has loaded and been sized
            welf.agreeButton.alpha = 1.0
            welf.disagreeButton.alpha = 1.0
        }
    }
}
