//
//  ChatNode.swift
//  QuickGuru
//
//  Created by Andrew Dolce on 12/12/16.
//  Copyright © 2016 Eli Lilly. All rights reserved.
//

import Foundation

protocol ChatNode {
    var identifier: String { get }
    var canContinue: Bool { get }
    func nextNodeIdentifier() -> String?
}
