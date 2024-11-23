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
