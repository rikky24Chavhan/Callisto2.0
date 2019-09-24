//
//  UIView+Nib.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 10/25/15.
//  Copyright © 2015 lowriDevs. All rights reserved.
//

import UIKit

public protocol TypeIdentifiable {
    static var identifier: String { get }
}

extension TypeIdentifiable {
    public static var identifier: String {
        return "identifier:\(self)"
    }
}

extension UITableViewCell: TypeIdentifiable {}
extension UITableViewHeaderFooterView: TypeIdentifiable {}
extension UICollectionReusableView: TypeIdentifiable {}



