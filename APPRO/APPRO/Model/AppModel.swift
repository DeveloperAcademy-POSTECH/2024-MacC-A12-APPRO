//
//  AppModel.swift
//  APPRO
//
//  Created by 정상윤 on 10/8/24.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
final class AppModel {
    
    let immersiveSpaceID = "ImmersiveSpace"
    let sharedSpaceObjectName: String = "Scene"
    let appTitle = "Stretchy"
    
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    
}
