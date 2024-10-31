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
    
    var contentEntity = Entity()
    var modelEntities: [Entity] = []
    var handEntities: [Entity] = []
    
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
    
    var isFistShowing: Bool = false
    var isFirstPositioning: Bool = true
    var isRightDone: Bool = false
    var rightHandTransform = Transform()
    
    func resetModelEntities() {
        modelEntities.forEach { entity in
            entity.removeFromParent()
        }
        modelEntities = []
    }

}

private extension ModelEntity {
    static func createHandEntity(isMarker: Bool = false)  -> ModelEntity {
        var modelEntity = ModelEntity()
        var clearMaterial = PhysicallyBasedMaterial()
        clearMaterial.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(scale: 0))
        if isMarker {
            modelEntity = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [clearMaterial])
            modelEntity.generateCollisionShapes(recursive: true)
            modelEntity.name = "Marker"
        } else {
            modelEntity = ModelEntity(mesh: .generateBox(size: 0.012), materials: [clearMaterial])
            modelEntity.name = "Finger"
        }
        return modelEntity
    }
}
