//
//  EyeStretchingViewModel+Configure.swift
//  APPRO
//
//  Created by 정상윤 on 11/23/24.
//

import RealityKit

extension EyeStretchingViewModel {
    
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
            self?.patchTapped()
        }
        try eyesObject.setPatchComponents([
            hoverEffectComponent,
            tapGestureComponent
        ])
        setClosureComponent(entity: eyesObject.entity, distance: .eyes)
    }
    
    func configureRingEntity() async throws {
        ringObject.entity.components.set(OpacityComponent(opacity: 0))
        ringObject.entity.setPosition(.init(x: 0, y: 0, z: 0), relativeTo: eyesObject.entity)
        ringObject.entity.orientation = eyesObject.entity.orientation
        try await ringObject.setCollisionComponent()
        try ringObject.subscribeCollisionEvent()
    }
    
    func configureMonitorEntity() {
        monitorEntity.transform.scale = [0.2, 0.2, 0.2]
        monitorEntity.transform.rotation = .init(angle: -0.5, axis: [0, 1, 0])
        monitorEntity.components.set(OpacityComponent(opacity: 0))
        monitorEntity.setPosition(.init(x: -0.15, y: -0.17, z: 0.35), relativeTo: ringObject.entity)
    }
    
    func setDisturbObjectsPosition() {
        let positions = generateDisturbObjectPositions()
        
        guard disturbObjects.count == positions.count else {
            dump("Disturb Entities and positions count mismatch")
            return
        }
        
        for (index, object) in disturbObjects.enumerated() {
            object.setPosition(positions[index], relativeTo: ringObject.entity)
        }
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
    
    private func generateDisturbObjectPositions() -> [Float3] {
        let width: Float = 1.1
        let height: Float = 0.7
        let dx: [Float] = [-1, 1, 1, -1]
        let dy: [Float] = [1, 1, -1, -1]
        var positions: Set<Float3> = []
        
        for angle in stride(from: Float(0.0), through: Float(90.0), by: Float(30.0)) {
            let radian = angle * (Float.pi / 180)
            for k in 0..<4 {
                let position = Float3(
                    round(dx[k] * width * cos(radian) * pow(10, 2)) / pow(10, 2),
                    round(dy[k] * height * sin(radian) * pow(10, 2)) / pow(10, 2),
                    0
                )
                positions.insert(position)
            }
        }
        return Array(positions)
    }
    
}

private extension Float {
    
    static let eyes = Float(2.0)
    static let attachment = Float(2.05)
    
}
