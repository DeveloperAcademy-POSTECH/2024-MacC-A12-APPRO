//
//  AppState.swift
//  APPRO
//
//  Created by 정상윤 on 10/8/24.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
final class AppState {
    
    let immersiveSpaceID = "ImmersiveSpace"
    let sharedSpaceWindowGroupID = "SharedSpaceWindowGroup"
    let fullSpaceWindowGroupID = "FullSpaceWindowGroup"
//    let sharedSpaceObjectName: String = "Scene"
    let appTitle = "Stretchy"
    
    var phase: AppPhase = .choosingStretchingPart
    
    var currentStretchingPart: Stretching? = nil
    
}
