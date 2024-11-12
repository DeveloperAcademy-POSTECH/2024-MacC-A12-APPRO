//
//  EyeStretchingEntityType.swift
//  APPRO
//
//  Created by 정상윤 on 11/12/24.
//

import Foundation

enum EyeStretchingEntityType: String {
    
    case eyes = "eyes_capsule"
    case chicken
    
    var loadURL: String {
        switch self {
        case .eyes:
            "Eye/eyes_loop.usd"
        case .chicken:
            "Eye/chicken.usd"
        }
    }
    
    var modelEntityNames: [String] {
        switch self {
        case .eyes:
            []
        case .chicken:
            ["Mesh_004", "Mesh_005"]
        }
    }
    
}
