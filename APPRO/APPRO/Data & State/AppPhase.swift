//
//  AppPhase.swift
//  APPRO
//
//  Created by 정상윤 on 10/13/24.
//

import Foundation

enum AppPhase: String, Sendable, Equatable {
    
    case choosingStretchingPart
    case isStretching
    
    var isImmersed: Bool {
        switch self {
        case .choosingStretchingPart:
            return false
        case .isStretching:
            return true
        }
    }
    
}
