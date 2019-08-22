//
//  SettingsViewController.swift
//  MealTrackingPilot
//
//  Created by Steve Galbraith on 8/8/18.
//  Copyright © 2018 Intrepid. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var navigationUnderlineToSafeAreaConstraint: NSLayoutConstraint!

    private struct Constants {
        static let copyrightCellHeight: CGFloat = 96.0
        static let navigationBarHeight: CGFloat = UIDevice.current.isRunningiOS10 ? 64 : 0
    }

    // MARK: - Lifecylcle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()
        setupNavigationBar()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Properties

    private var navBarTitleView: UILabel {
        let label = UILabel()
        label.text = "Settings"
        label.font = .openSansSemiboldFont(size: 17)
        label.textAlignment = .center
        label.textColor = .piDenim
        label.frame.size = label.intrinsicContentSize

        return label
    }

    // MARK: - Setup

    private func setupNavigationItem() {
        navigationItem.titleView = navBarTitleView
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "buttonBackarrow"), style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem?.tintColor = .piDenim
        navigationItem.backBarButtonItem = UIBarButtonItem.emptyBackItem()
    }

    private func setupNavigationBar() {
        guard let navigationBar = navigationController?.navigationBar else { return }

        navigationBar.barStyle = .default
        navigationUnderlineToSafeAreaConstraint.constant = Constants.navigationBarHeight
    }

    private func setupTableView() {
        tableView.estimatedRowHeight = SettingTableViewCell.preferredHeight
        tableView.separatorStyle = .none

        SettingTableViewCell.registerNib(tableView)
        CopyrightTableViewCell.registerNib(tableView)
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section > 0 {
            return 1
        } else {
            return StatementType.allValues.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CopyrightTableViewCell.cellIdentifier, for: indexPath)
            cell.selectionStyle = .none

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingTableViewCell.cellIdentifier, for: indexPath) as! SettingTableViewCell
            cell.selectionStyle = .none
            let statementType = StatementType.allValues[indexPath.row]
            cell.settingTitleLabel.text = statementType.rawValue

            return cell
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section > 0 {
            let contentHeight = SettingTableViewCell.preferredHeight * CGFloat(tableView.numberOfRows(inSection: 0))
            let proposedHeight = tableView.frame.height - contentHeight
            return proposedHeight > Constants.copyrightCellHeight ? proposedHeight : Constants.copyrightCellHeight
        } else {
            return UITableViewAutomaticDimension
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section < 1 {
            let statementType = StatementType.allValues[indexPath.row]

            let statementViewController = StatementViewController(ofType: statementType)
            present(statementViewController, animated: true, completion: nil)
        }
    }
}
