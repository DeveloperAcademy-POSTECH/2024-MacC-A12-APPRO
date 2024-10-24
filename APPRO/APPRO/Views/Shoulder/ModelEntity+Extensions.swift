//
//  ModelEntity+Extensions.swift
//  ParabolaTest
//
//  Created by Damin on 10/12/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

extension ModelEntity {
    static func createHandEntity(isWrist: Bool = false, number: Int)  -> ModelEntity {
        
        var modelEntity = ModelEntity()
        var simpleMaterial: SimpleMaterial = .init()
        var clearMaterial = PhysicallyBasedMaterial()
        clearMaterial.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(scale: 0))
        if isWrist {
            simpleMaterial = SimpleMaterial(color: UIColor(hex: "FFDA8C"), isMetallic: false)
            modelEntity = ModelEntity(mesh: .generateSphere(radius: 0.04), materials: [simpleMaterial])
            
        } else {
//            simpleMaterial = SimpleMaterial(color: UIColor(hex: "FFFFFF"), isMetallic: false)
            modelEntity = ModelEntity(mesh: .generateBox(size: 0.012), materials: [clearMaterial])
        }
        
        modelEntity.generateCollisionShapes(recursive: true)
        modelEntity.physicsBody = PhysicsBodyComponent()
        modelEntity.physicsBody?.isAffectedByGravity = false
        modelEntity.physicsBody?.isTranslationLocked = (true, true, true)
        modelEntity.name = "Hand-\(number)"
        
       
        
        return modelEntity
    }
    
    static func createArmEntity() -> ModelEntity {
        let simpleMaterial = SimpleMaterial(color: UIColor.green, isMetallic: false)
        let modelEntity = ModelEntity(mesh: .generateBox(width: 0.5, height: 0.05, depth: 0.1), materials: [simpleMaterial])
        return modelEntity
    }
    
    static func createEnvironmentEntity() -> Entity {
        let bgColor: UIColor = .white
        var material = UnlitMaterial()
        material.color = UnlitMaterial.BaseColor(tint: bgColor)
        
        let environment = Entity()
        environment.components.set(ModelComponent(
            mesh: .generateSphere(radius: 2000),
            materials: [material]
        ))
        environment.scale *= .init(x: -2, y: 2, z: 2)
        return environment
    }
    
    static func makeText(text: String) -> ModelEntity {
        let materialVar = SimpleMaterial(color: .black, roughness: 0, isMetallic: false)
        
        let depthVar: Float = 0.1
        let fontVar = UIFont.systemFont(ofSize: 0.3)
        // containerFrame을 넣으면 모델이 안나옴
        let containerFrameVar = CGRect.zero
        let alignmentVar: CTTextAlignment = .center
        let lineBreakModeVar : CTLineBreakMode = .byWordWrapping
        
        let textMeshResource : MeshResource = .generateText(
            text,
            extrusionDepth: depthVar,
            font: fontVar,
            containerFrame: containerFrameVar,
            alignment: alignmentVar,
            lineBreakMode: lineBreakModeVar
        )
        
        let textModelEntity = ModelEntity(
            mesh: textMeshResource,
            materials: [materialVar]
        )
        textModelEntity.name = "text-\(text)"
        var textBoundingBox = BoundingBox.empty
        textBoundingBox = textMeshResource.bounds
        
        let boundsExtents = textBoundingBox.extents * textModelEntity.scale
        
        textModelEntity.scale = textModelEntity.scale * 0.07
        return textModelEntity
    }
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(color & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
