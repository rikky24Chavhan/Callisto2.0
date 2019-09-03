//
//  DashboardHeaderViewModel.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/15/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import UIKit

protocol DashboardHeaderViewModel {
    var primaryText: NSAttributedString { get }
    var secondaryText: NSAttributedString { get }
}

public final class DashboardDateHeaderViewModel: DashboardHeaderViewModel {

    // MARK: - Properties

    private struct Constants {
        static let dateFormat = "MMM dd, YYYY"
    }

    private let date: Date

    lazy var primaryText: NSAttributedString = {
        return NSAttributedString(
            string: self.date.weekdayName,
            attributes: [
                NSAttributedString.Key.foregroundColor : UIColor.piDenim.withAlphaComponent(0.8),
                NSAttributedString.Key.font : UIFont.openSansSemiboldFont(size: 14)
            ])
    }()

    lazy var secondaryText: NSAttributedString = {
        let dateString = self.date.string(custom: Constants.dateFormat).uppercased()
        return NSAttributedString(
            string: dateString,
            attributes: [
                NSAttributedString.Key.foregroundColor : UIColor.piDenim.withAlphaComponent(0.8),
                NSAttributedString.Key.font : UIFont.openSansFont(size: 12)
            ])
    }()

    // MARK: - Lifecycle

    init(date: Date) {
        self.date = date
    }
}

public final class MealJournalHeaderViewModel: DashboardHeaderViewModel {

    private struct Constants {
        static let baselineOffset = 2.0
    }

    let primaryText: NSAttributedString = NSAttributedString(
        string: "Meal Journal",
        attributes: [
            NSAttributedString.Key.foregroundColor : UIColor.piDenim,
            NSAttributedString.Key.font : UIFont.openSansSemiboldFont(size: 16),
            NSAttributedString.Key.baselineOffset : Constants.baselineOffset
        ])

    let secondaryText: NSAttributedString = NSAttributedString(
        string: "Swipe up to view",
        attributes: [
            NSAttributedString.Key.foregroundColor : UIColor.piGreyblue,
            NSAttributedString.Key.font : UIFont.openSansItalicFont(size: 14),
            NSAttributedString.Key.baselineOffset : Constants.baselineOffset
        ])
}
