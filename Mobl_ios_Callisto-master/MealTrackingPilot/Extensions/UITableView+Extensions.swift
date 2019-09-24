//
//  UITableView+Extensions.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 5/19/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

extension UITableView {

    // Workaround for improper layout in tableHeaderView (https://gist.github.com/marcoarment/1105553afba6b4900c10)
    func layoutTableHeaderView() {
        guard let headerView = self.tableHeaderView else { return }

        // Perform layout of header view with temporary width constraint
        headerView.translatesAutoresizingMaskIntoConstraints = false

        let temporaryWidthConstraint: NSLayoutConstraint! = headerView.constrainView(
            headerView,
            toWidth: self.bounds.width)

        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()

        // Update frame with suggested height while width constraint is still in place
        let headerSize = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let height = headerSize.height
        var frame = headerView.frame

        frame.size.height = height
        headerView.frame = frame

        self.tableHeaderView = headerView

        // Remove unneeded width constraint after height is set correctly
        headerView.removeConstraint(temporaryWidthConstraint)
        headerView.translatesAutoresizingMaskIntoConstraints = true
    }

    var maxContentOffset: CGPoint {
        let verticalInsets = contentInset.top + contentInset.bottom
        let maxYOffset = contentSize.height + verticalInsets - frame.height
        return CGPoint(x: 0, y: max(0, maxYOffset))
    }
}
