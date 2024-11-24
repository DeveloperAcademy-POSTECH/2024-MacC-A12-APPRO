//
//  EyeTutorialManager+Configure.swift
//  APPRO
//
//  Created by 정상윤 on 11/12/24.
//

import SwiftUI
import RealityKit

extension EyeTutorialManager {
    
    func configureAttachmentView() {
        setClosureComponent(
            entity: attachmentView,
            distance: .attachment,
            upward: 0.4
        )
    }
    
    func configureEyesEntity() throws {
        let hoverEffectComponent = HoverEffectComponent(.spotlight(.default))
        let tapGestureComponent = TapGestureComponent { [weak self] in
            self?.step1Done()
        }
        try eyesEntity.setPatchComponents([
            hoverEffectComponent, tapGestureComponent
        ])
        setClosureComponent(entity: eyesEntity, distance: .eyes)
    }
    
    func configureChickenEntity() throws {
        chickenEntity.setPosition(.init(x: -1, y: 0, z: 0), relativeTo: eyesEntity)
        chickenEntity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        chickenEntity.components.set(OpacityComponent(opacity: 0.0))
        chickenEntity.components.set(HoverEffectComponent(.spotlight(.default)))
        
        let longPressGesture = LongPressGestureComponent { [weak self] in
            self?.longPressOnEnded()
        }
        try chickenEntity.setGestureComponent(
            type: .chicken,
            component: longPressGesture
        )
    }
    
    func configureRingEntity() async throws {
        ringEntity.components.set(OpacityComponent(opacity: 0))
        ringEntity.setPosition(.init(x: 0, y: 0, z: 0), relativeTo: eyesEntity)
        ringEntity.orientation = eyesEntity.orientation
        try await ringEntity.setCollisionComponent()
    }
    
    func configureMonitorEntity() {
        monitorEntity.transform.scale = [0.2, 0.2, 0.2]
        monitorEntity.transform.rotation = .init(angle: -0.5, axis: [0, 1, 0])
        monitorEntity.components.set(OpacityComponent(opacity: 0))
        monitorEntity.setPosition(.init(x: -0.15, y: -0.17, z: 0.35), relativeTo: ringEntity)
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
    
}

private extension Float {
    
    static let eyes = Float(2.0)
    static let attachment = Float(2.05)
    
}
