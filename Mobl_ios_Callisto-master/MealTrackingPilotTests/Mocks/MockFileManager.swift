//
//  MockFileManager.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 4/11/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

class MockFileManager: FileManager {
    let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

    override func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        return [temporaryDirectoryURL]
    }
}
