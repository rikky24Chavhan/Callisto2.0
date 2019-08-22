//
//  DashboardHeaderViewModel.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/15/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import SwiftDate

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
                NSAttributedStringKey.foregroundColor : UIColor.piDenim.withAlphaComponent(0.8),
                NSAttributedStringKey.font : UIFont.openSansSemiboldFont(size: 14)
            ])
    }()

    lazy var secondaryText: NSAttributedString = {
        let dateString = self.date.string(custom: Constants.dateFormat).uppercased()
        return NSAttributedString(
            string: dateString,
            attributes: [
                NSAttributedStringKey.foregroundColor : UIColor.piDenim.withAlphaComponent(0.8),
                NSAttributedStringKey.font : UIFont.openSansFont(size: 12)
            ])
    }()

    // MARK: - Lifecycle

    init(date: Date) {
        self.date = date
    }
}

public final class MealJournalHeaderViewModel: DashboardHeaderViewModel {

    private struct Constants {
        static let baselineOffset: CGFloat = 2.0
    }

    let primaryText: NSAttributedString = NSAttributedString(
        string: "Meal Journal",
        attributes: [
            NSAttributedStringKey.foregroundColor : UIColor.piDenim,
            NSAttributedStringKey.font : UIFont.openSansSemiboldFont(size: 16),
            NSAttributedStringKey.baselineOffset : Constants.baselineOffset
        ])

    let secondaryText: NSAttributedString = NSAttributedString(
        string: "Swipe up to view",
        attributes: [
            NSAttributedStringKey.foregroundColor : UIColor.piGreyblue,
            NSAttributedStringKey.font : UIFont.openSansItalicFont(size: 14),
            NSAttributedStringKey.baselineOffset : Constants.baselineOffset
        ])
}
