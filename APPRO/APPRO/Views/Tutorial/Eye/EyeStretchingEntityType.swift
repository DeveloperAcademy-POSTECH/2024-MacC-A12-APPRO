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
    
    var loadURL: String {
        switch self {
        case .eyes:
            "Eye/eyes_loop.usd"
        case .chicken:
            "Eye/chicken.usd"
        }
    }
    
}
