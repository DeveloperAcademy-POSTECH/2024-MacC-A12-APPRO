//
//  EyeTutorialManager+Configure.swift
//  APPRO
//
//  Created by 정상윤 on 11/12/24.
//

import SwiftUI
import RealityKit

extension EyeTutorialManager {
    
    func configureAttachmentView(entity: Entity) {
        setClosureComponent(
            entity: attachmentView,
            distance: .attachment,
            upward: 0.01,
            forwardDirection: .positiveZ
        )
    }
    
    func configureEyesEntity(entity: Entity) {
        setClosureComponent(entity: entity, distance: .eyes)
        entity.findEntity(named: "patch")?.components.set(HoverEffectComponent(.highlight(.default)))
    }
    
    func configureChickenEntity(entity: Entity) {
        entity.setPosition(.init(x: 2, y: 0, z: 0), relativeTo: eyesEntity)
        entity.components.set(HoverEffectComponent(.highlight(.default)))
        entity.components.set(OpacityComponent(opacity: 0.0))
        entity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        setCollisionComponent(entity: entity, type: .chicken)
    }
    
    private func setClosureComponent(
        entity: Entity,
        distance: Float,
        upward: Float = 0,
        forwardDirection: Entity.ForwardDirection = .negativeZ
    ) {
        let closureComponent = ClosureComponent { [weak self] deltaTime in
            guard let currentTransform = self?.headTracker.originFromDeviceTransform() else { return }
            
            let currentTranslation = currentTransform.translation()
            let targetPosition = currentTranslation - distance * currentTransform.forward()
            let ratio = Float(pow(0.96, deltaTime / (16 * 1E-3)))
            var newPosition = ratio * entity.position(relativeTo: nil) + (1 - ratio) * targetPosition
            newPosition.y += upward
            entity.look(at: currentTranslation, from: newPosition, relativeTo: nil, forward: forwardDirection)
        }
        entity.components.set(closureComponent)
    }
    
    private func setCollisionComponent(
        entity: Entity,
        type: EyeStretchingEntityType
    ) {
        let modelEntities = type.modelEntityNames.compactMap { entity.findEntity(named: $0) as? ModelEntity }
        
        Task { @MainActor in
            do {
                for modelEntity in modelEntities {
                    if let mesh = modelEntity.model?.mesh {
                        let shape = try await ShapeResource.generateStaticMesh(from: mesh)
                        modelEntity.components.set(CollisionComponent(shapes: [shape]))
                    }
                }
            } catch {
                dump(error)
            }
        }
    }
    
}

private extension Float {
    
    static let eyes = Float(2.0)
    static let attachment = Float(2.05)
    
}
