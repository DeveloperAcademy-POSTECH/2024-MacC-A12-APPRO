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
            upward: 0.4
        )
    }
    
    func configureEyesEntity() throws {
        try eyesEntity.setPatchHoverEffectComponent()
        setClosureComponent(entity: eyesEntity, distance: .eyes)
    }
    
    func configureChickenEntity() {
        chickenEntity.setPosition(.init(x: -1, y: 0, z: 0), relativeTo: eyesEntity)
        chickenEntity.components.set(HoverEffectComponent(.highlight(.default)))
        chickenEntity.components.set(OpacityComponent(opacity: 0.0))
        chickenEntity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        chickenEntity.generateCollisionShapes(recursive: true)
    }
    
    func configureRingEntity() async throws {
        ringEntity.components.set(OpacityComponent(opacity: 0))
        ringEntity.setPosition(.init(x: 0, y: 0, z: 0), relativeTo: eyesEntity)
        ringEntity.orientation = eyesEntity.orientation
        try await ringEntity.setCollisionComponent()
    }
    
    func configureMonitorEntity() {
        monitorEntity.components.set(OpacityComponent(opacity: 0))
        monitorEntity.setPosition(.init(x: -0.1, y: -0.05, z: 0.2), relativeTo: ringEntity)
    }
    
    private func setClosureComponent(
        entity: Entity,
        distance: Float,
        upward: Float = 0,
        forwardDirection: Entity.ForwardDirection = .positiveZ
    ) {
        let closureComponent = ClosureComponent { [weak self] deltaTime in
            guard let currentTransform = self?.headTracker.originFromDeviceTransform() else { return }
            
            let currentTranslation = currentTransform.translation()
            var targetPosition = currentTranslation - distance * currentTransform.forward()
            targetPosition.y += upward
            entity.look(at: currentTranslation, from: targetPosition, relativeTo: nil, forward: forwardDirection)
        }
        entity.components.set(closureComponent)
    }
    
    private func generateShapeResource(entity: Entity, isConvex: Bool) async -> ShapeResource? {
        guard let modelEntity = entity.children.filter({ $0 is ModelEntity }).first as? ModelEntity,
              let mesh = modelEntity.model?.mesh else {
            dump("generateShapeResourceByMesh failed: No mesh found in \(entity.name)")
            return nil
        }
        
        do {
            return isConvex
            ? try await ShapeResource.generateConvex(from: mesh)
            : try await ShapeResource.generateStaticMesh(from: mesh)
        } catch {
            dump("generateShapeResourceByMesh failed: \(error)")
            return nil
        }
    }
    
}

private extension Float {
    
    static let eyes = Float(2.0)
    static let attachment = Float(2.05)
    
}
