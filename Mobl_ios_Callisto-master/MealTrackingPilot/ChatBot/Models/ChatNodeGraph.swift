//
//  ChatNodeGraph.swift
//  QuickGuru
//
//  Created by Andrew Dolce on 12/12/16.
//  Copyright © 2016 Eli Lilly. All rights reserved.
//

import Foundation

protocol ChatNodeGraph {
    func startingIdentifier() -> String
    func nodeForIdentifier(_ identifier: String) -> ChatNode?
}
