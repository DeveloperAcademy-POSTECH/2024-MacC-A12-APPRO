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

    init() {
        var clearMaterial = PhysicallyBasedMaterial()
        clearMaterial.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(floatLiteral: 0))
        var fingerModelEntity = ModelEntity()

        let opacityComponent = OpacityComponent(opacity: 0)

        fingerModelEntity = ModelEntity(mesh: .generateBox(size: 0.012), materials: [clearMaterial])
        fingerModelEntity.components.set(opacityComponent)
        fingerModelEntity.name = "Finger"
        
        self.thumbIntermediateBaseModelEntity = fingerModelEntity
        self.indexFingerTipModelEntity = fingerModelEntity
    }

}
