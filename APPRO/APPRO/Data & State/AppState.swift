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
    
    var currentStretching: Stretching? {
        if case .isStretching(let stretching) = appPhase {
            return stretching
        } else {
            return nil
        }
    }
    
    var tutorialManager: TutorialManager? = nil
    
    var doneCount = 0
    private(set) var maxCount = 0
    
    func resetStretchingCount() {
        if let stretching = currentStretching {
            doneCount = 0
            maxCount = (stretching == .eyes || stretching == .wrist) ? 12 : 3
        } else {
            dump("resetStretchingCount unexpectedly called")
        }
    }
    
}
