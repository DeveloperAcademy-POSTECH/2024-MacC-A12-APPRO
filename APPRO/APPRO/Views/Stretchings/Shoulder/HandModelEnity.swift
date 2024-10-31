//
//  HandModelEnity.swift
//  APPRO
//
//  Created by Damin on 10/31/24.
//

import RealityKit
import RealityKitContent

struct HandModelEntity {
    let thumbIntermediateBaseModelEntity: ModelEntity
    let indexFingerTipModelEntity: ModelEntity
    let rocketEntity: ModelEntity
    
    init() {
        var clearMaterial = PhysicallyBasedMaterial()
        clearMaterial.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(scale: 0))
        var fingerModelEntity = ModelEntity()
        var markerModelEntity = ModelEntity()
        
        markerModelEntity = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [clearMaterial])
        markerModelEntity.generateCollisionShapes(recursive: true)
        markerModelEntity.name = "Marker"
        
        fingerModelEntity = ModelEntity(mesh: .generateBox(size: 0.012), materials: [clearMaterial])
        fingerModelEntity.name = "Finger"
        
        self.thumbIntermediateBaseModelEntity = fingerModelEntity
        self.indexFingerTipModelEntity = fingerModelEntity
        self.rocketEntity = markerModelEntity
        
        setupRocketEntity()
    }
    
    private func setupRocketEntity() {
        Task {
            if let rootEntity = try? await Entity(named: "Shoulder/RocketScene.usda", in: realityKitContentBundle) {
                await rocketEntity.addChild(rootEntity)
            }
        }
    }
}
