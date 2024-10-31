//
//  ShoulderStretchingViewModel.swift
//  APPRO
//
//  Created by Damin on 10/31/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

@Observable
@MainActor
final class ShoulderStretchingViewModel {
    
    let session = ARKitSession()
    var handTrackingProvider = HandTrackingProvider()
    var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    // right
    var rightThumbIntermediateBaseModelEntity = ModelEntity.createHandEntity()
    var rightIndexFingerTipModelEntity = ModelEntity.createHandEntity()
    var rightRocketEntity = ModelEntity.createHandEntity(isMarker: true)
    // left
    var leftIndexFingerIntermediateBaseModelEntity = ModelEntity.createHandEntity()
    var leftIndexFingerTipModelEntity = ModelEntity.createHandEntity()
    var leftRocketEntity = ModelEntity.createHandEntity(isMarker: true)
}

