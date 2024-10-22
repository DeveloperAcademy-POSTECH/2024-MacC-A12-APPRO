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
    
    let stretchingPartsWindowID = "StretchingPartsWindow"
    let stretchingProcessWindowID = "StretchingProcessWindow"
    let immersiveSpaceID = "StretchingSpace"
    
    var appPhase: AppPhase = .choosingStretchingPart
    
}
