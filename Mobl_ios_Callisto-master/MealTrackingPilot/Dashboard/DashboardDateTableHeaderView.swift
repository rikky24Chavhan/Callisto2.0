//
//  DashboardDateTableHeaderView.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/21/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

// Table view header view wrapper around DashboardDateHeaderView
final class DashboardDateTableHeaderView: UITableViewHeaderFooterView {

    static let estimatedHeight: CGFloat = 41
    
    // MARK: - Properties

    var viewModel: DashboardHeaderViewModel? {
        didSet {
            headerview.viewModel = viewModel
        }
    }

    var isTopHeader: Bool = false {
        didSet {
            headerview.isTopHeader = isTopHeader
        }
    }

    private var headerview: DashboardDateHeaderView = {
        let headerView = DashboardDateHeaderView(frame: .zero)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()

    // MARK: - Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isTopHeader = false
    }

    // MARK: Setup

    func setup() {
        contentView.backgroundColor = .clear
        let headerBackgroundview = UIView()
        headerBackgroundview.backgroundColor = .clear
        backgroundView = headerBackgroundview

        setupHeaderView()
    }

    func setupHeaderView() {
        contentView.addSubview(headerview)

        contentView.constrainView(toAllEdges: headerview)
    }

}
