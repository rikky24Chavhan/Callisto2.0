//
//  Sounds.swift
//  QuickGuru
//
//  Created by Andrew Dolce on 12/20/16.
//  Copyright © 2016 Eli Lilly. All rights reserved.
//

import Foundation
import AudioToolbox

enum Sound: UInt32 {
    case messageReceived = 1003
    case messageSent = 1004

    func play(asAlert: Bool = false) {
        if asAlert {
            AudioServicesPlayAlertSound(rawValue)
        } else {
            AudioServicesPlaySystemSound(rawValue)
        }
    }
}
