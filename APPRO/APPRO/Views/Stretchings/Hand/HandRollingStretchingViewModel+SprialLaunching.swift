//
//  HandRollingStretchingViewModel+SprialLaunching.swift
//  APPRO
//
//  Created by marty.academy on 10/31/24.
//

import SwiftUI
import ARKit
import RealityKit
import RealityKitContent

extension HandRollingStretchingViewModel {
    
    func generateLaunchObj(chirality: Chirality) async throws -> Entity {
        if let custom3DObject = try? await Entity(named: "Hand/spiral_new", in: realityKitContentBundle) {
            let rotationNumber = chirality == .left ? leftRotationForLaunchNumber : rightRotationForLaunchNumber
            custom3DObject.name = "Spiral_\(chirality)_\(rotationNumber)"
            
            custom3DObject.components.set(GroundingShadowComponent(castsShadow: true))
            custom3DObject.components.set(InputTargetComponent())
            custom3DObject.generateCollisionShapes(recursive: true)
            
            custom3DObject.scale = .init(repeating: 0.01)
            
            let physicsMaterial = PhysicsMaterialResource.generate(
                staticFriction: 0.01,
                dynamicFriction: 0.01,
                restitution: 1.5
            )
            
            var physicsBody = PhysicsBodyComponent(massProperties: .default, material: physicsMaterial, mode: .dynamic)
            physicsBody.isAffectedByGravity = false
            physicsBody.massProperties.mass = 0.01
            
            let startingCriteria = chirality == .right ? rightGuideRing : leftGuideRing
            custom3DObject.transform = startingCriteria.transform
            
            let forwardDirection = startingCriteria.transform.matrix.columns.0 // x axis
            let direction = simd_float3(forwardDirection.x, forwardDirection.y, forwardDirection.z)
            let adjustedTranslation = chirality == .left ? startingCriteria.position - direction * 0.25 : startingCriteria.position + direction * 0.25
            
            custom3DObject.transform.translation = adjustedTranslation
            
            if let modelEntity = custom3DObject.findEntity(named: "Spiral") as? ModelEntity {
                modelEntity.components[PhysicsBodyComponent.self] = physicsBody
            }
            
            try await animating(entity: custom3DObject, chirality: chirality)
            
            return custom3DObject
        }
        
        return Entity()
    }
    
    func playSpatialAudio(_ entity: Entity, spatialAudioName: String, resourceLocation: String, resourceFrom: String) async throws {
        guard let entity = entity.findEntity(named: spatialAudioName),
              let resource = try? await AudioFileResource(named: resourceLocation,
                                                          from: resourceFrom,
                                                          in: realityKitContentBundle) else { return }
        
        let audioPlayer = entity.prepareAudio(resource)
        audioPlayer.play()
    }
    
    func playAppearAudio(_ entity: Entity) async throws {
        try await playSpatialAudio(entity, spatialAudioName: "AppearSpatialAudio", resourceLocation:"/Root/spiral_come_out_wav", resourceFrom: "spiral_consistent.usd")
    }
    
    func playCollisionAudio(_ modelEntity: ModelEntity) async throws {
        guard let entity = modelEntity.parent?.parent?.parent else { return }
        
        try await playSpatialAudio(entity, spatialAudioName: "CollisionSpatialAudio", resourceLocation: "/Root/spiral_collide_wav", resourceFrom: "spiral_consistent.usd")
    }
    
    func animating(entity : Entity, chirality : Chirality) async throws {
        let multiplication = entity.transform.matrix
        let forwardDirection = multiplication.columns.0 // x axis
        let direction = simd_float3(forwardDirection.x, forwardDirection.y, forwardDirection.z)
        
        let moveTargetPosition = chirality == .left ? entity.position - direction * 1.5 : entity.position + direction * 1.5
        
        var shortTransform = entity.transform
        shortTransform.scale = .init(repeating: 0.1)
        
        var newTransform = entity.transform
        newTransform.translation = moveTargetPosition
        newTransform.scale = .init(repeating: 1)
        
        let goInDirection = FromToByAnimation<Transform> (
            name: "launchFromWrist",
            from: shortTransform,
            to: newTransform,
            duration: 0.5,
            bindTarget: .transform
        )
        
        let animation = try AnimationResource.generate(with: goInDirection)
        
        entity.playAnimation(animation, transitionDuration: 2)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            entity.removeFromParent()
        }
        
        try await playAppearAudio(entity)
    }
}
