//
//  PilotRequest+DownloadImage.swift
//  MealTrackingPilot
//
//  Created by Steve Galbraith on 8/2/18.
//  Copyright © 2018 Intrepid. All rights reserved.
//

import Foundation

extension PilotRequest {
    static func downloadImage(at url: URL) -> PilotRequest {
        let tokenStorage =  JsonWebTokenStorage()
        return PilotRequest(
            method: .GET,
            path: url.absoluteString.replacingOccurrences(of: "/api/v1/", with: ""),
            accessCredentials: tokenStorage.accessCredentials
        )
    }
}
