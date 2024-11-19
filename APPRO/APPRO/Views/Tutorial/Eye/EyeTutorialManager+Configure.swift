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
    
    func configureEyesEntity(entity: Entity) {
        setClosureComponent(entity: entity, distance: .eyes)
        entity.findEntity(named: "patch")?.components.set(HoverEffectComponent(.highlight(.default)))
    }
    
    func setEyeCollisionComponent(entity: Entity) async {
        guard let leftEyeEntity = entity.findEntity(named: "eye_left"),
              let rightEyeEntity = entity.findEntity(named: "eye_right") else {
            dump("setEyeCollisionComponent failed: cannot find eye entities")
            return
        }
        
        guard let leftShapeResource = await generateShapeResource(entity: leftEyeEntity, isConvex: true),
        let rightShapeResource = await generateShapeResource(entity: rightEyeEntity, isConvex: true) else {
            return
        }
        leftEyeEntity.components.set(CollisionComponent(shapes: [leftShapeResource]))
        rightEyeEntity.components.set(CollisionComponent(shapes: [rightShapeResource]))
    }
    
    func configureChickenEntity(entity: Entity) {
        entity.setPosition(.init(x: -1, y: 0, z: 0), relativeTo: eyesEntity)
        entity.components.set(HoverEffectComponent(.highlight(.default)))
        entity.components.set(OpacityComponent(opacity: 0.0))
        entity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        entity.generateCollisionShapes(recursive: true)
    }
    
    func configureRingEntity(entity: Entity) async {
        ringEntity.components.set(OpacityComponent(opacity: 0))
        ringEntity.setPosition(.init(x: 0, y: 0, z: 0), relativeTo: eyesEntity)
        ringEntity.orientation = eyesEntity.orientation
        
        await setRingCollisionComponent(entity: entity)
    }
    
    func configureMonitorEntity(entity: Entity) {
        entity.components.set(OpacityComponent(opacity: 0))
        entity.setPosition(.init(x: -0.1, y: -0.05, z: 0.2), relativeTo: ringEntity)
    }
    
    private func setRingCollisionComponent(entity: Entity) async {
        guard let innerPlaneEntity = ringEntity.findEntity(named: "inner_plane"),
              let restrictLineEntity = ringEntity.findEntity(named: "restrict_line") else {
            dump("configureRingChildrenEntities failed: No innerPlaneEntity or restrictLineEntity found")
            return
        }
        
        guard let innerPlaneShapeResource = await generateShapeResource(entity: innerPlaneEntity, isConvex: true),
              let restrictLineShapeResource = await generateShapeResource(entity: restrictLineEntity, isConvex: false) else {
            return
        }
        
        innerPlaneEntity.components.set(CollisionComponent(shapes: [innerPlaneShapeResource], isStatic: true))
        restrictLineEntity.components.set(CollisionComponent(shapes: [restrictLineShapeResource], isStatic: true))
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
