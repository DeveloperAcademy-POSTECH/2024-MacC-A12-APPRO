//
//  ShoulderStretchingViewModel+HandTraking.swift
//  APPRO
//
//  Created by Damin on 10/31/24.
//

import Foundation
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
