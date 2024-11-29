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

extension HandRollingTutorialViewModel {
    
    func generateLaunchObj(chirality: Chirality) async -> Entity {
        if spiralOriginal.name == "" {
            guard let spiralLoadedFromRCP = try? await Entity(named: "Hand/spiral_new", in: realityKitContentBundle) else { return Entity() }
            spiralOriginal = spiralLoadedFromRCP
        }
        
        let spiralEntity = spiralOriginal.clone(recursive: true)
        let rotationNumber = chirality == .right ? rightRotationForLaunchNumber : leftRotationForLaunchNumber
        spiralEntity.name = "Spiral_\(chirality)_\(rotationNumber)"
        
        spiralEntity.components.set(GroundingShadowComponent(castsShadow: true))
        spiralEntity.components.set(InputTargetComponent())
        spiralEntity.generateCollisionShapes(recursive: true)
        
        spiralEntity.scale = .init(repeating: 0.01)
        
        let physicsMaterial = PhysicsMaterialResource.generate(
            staticFriction: 0.01,
            dynamicFriction: 0.01,
            restitution: 1.5
        )
        
        var physicsBody = PhysicsBodyComponent(massProperties: .default, material: physicsMaterial, mode: .dynamic)
        physicsBody.isAffectedByGravity = false
        physicsBody.massProperties.mass = 0.01
        
        let startingCriteria = chirality == .right ? rightGuideRing : leftGuideRing
        spiralEntity.transform = startingCriteria.transform
        
        let forwardDirection = startingCriteria.transform.matrix.columns.0 // x axis
        let direction = simd_float3(forwardDirection.x, forwardDirection.y, forwardDirection.z)
        let adjustedTranslation = startingCriteria.position - direction * 0.25
        
        spiralEntity.transform.translation = adjustedTranslation
        
        if let modelEntity = spiralEntity.findEntity(named: "Spiral") as? ModelEntity {
            modelEntity.components[PhysicsBodyComponent.self] = physicsBody
        }
        
        try? animating(entity: spiralEntity, chirality: chirality)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if chirality == .right {
                guard let indexOfEntity = self.rightEntities.firstIndex(where: { $0.name == spiralEntity.name}) else { return }
                self.rightEntities.remove(at: indexOfEntity)
            } else {
                guard let indexOfEntity = self.leftEntities.firstIndex(where: { $0.name == spiralEntity.name}) else { return }
                self.leftEntities.remove(at: indexOfEntity)
            }
            spiralEntity.removeFromParent()
        }
        
        return spiralEntity
    }
    
    func animating(entity : Entity, chirality : Chirality) throws {
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
        
        guard let animation = try? AnimationResource.generate(with: goInDirection) else {
            debugPrint("Failed to generate animation")
            return
        }
        
        entity.playAnimation(animation, transitionDuration: 0.5)
        
        soundHelper.playSound(.handSprialAppear, on: entity)
    }
}
