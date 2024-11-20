//
//  EyeStretchingEntityType.swift
//  APPRO
//
//  Created by 정상윤 on 11/12/24.
//

import Foundation

enum EyeStretchingEntityType {
    
    case eyes
    case disturbEntity(type: DisturbEntityType)
    case ring
    case monitor
    
    var loadURL: String {
        switch self {
        case .eyes:
            "Eye/eyes.usd"
        case .disturbEntity(let type):
            "Eye/DisturbEntity/\(type.rawValue).usd"
        case .ring:
            "Eye/eye_ring.usd"
        case .monitor:
            "Eye/monitor.usd"
        }
    }
    
}

enum DisturbEntityType: String {
    
    case chicken
    case game
    case basketball
    case burger
    case pillow
    case popcorn
    
}
