//
//  EyeStretchingEntityType.swift
//  APPRO
//
//  Created by 정상윤 on 11/12/24.
//

import Foundation

enum EyeStretchingEntityType: String {
    
    case eyes
    case chicken
    case ring
    case monitor
    
    var loadURL: String {
        switch self {
        case .eyes:
            "Eye/eyes.usd"
        case .chicken:
            "Eye/chicken.usd"
        case .ring:
            "Eye/eye_ring.usd"
        case .monitor:
            "Eye/monitor.usd"
        }
    }
    
}
