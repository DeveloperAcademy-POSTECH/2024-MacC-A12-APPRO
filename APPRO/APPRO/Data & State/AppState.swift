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
    let stretchingTutorialWindowID = "StretchingTutorialWindow"
    let stretchingEndWindowId = "StretchingEndWindow"
    let immersiveSpaceID = "StretchingSpace"
    
    var appPhase: AppPhase = .choosingStretchingPart
    
    var currentStretchingPart: StretchingPart? = nil
    
    var doneCount = 0
    private(set) var maxCount = 0
    
    func resetStretchingCount() {
        if let stretching = currentStretchingPart {
            doneCount = 0
            maxCount = stretching.maxCount
        } else {
            dump("resetStretchingCount unexpectedly called")
        }
    }
    
}
