//
//  AppPhase.swift
//  APPRO
//
//  Created by 정상윤 on 10/22/24.
//

import Foundation

enum AppPhase: Sendable, Equatable {
    
    case choosingStretchingPart
    case tutorial
    case stretching
    
    var isImmersed: Bool {
        switch self {
        case .choosingStretchingPart:
            return false
        case .tutorial, .stretching:
            return true
        }
    }
    
}
