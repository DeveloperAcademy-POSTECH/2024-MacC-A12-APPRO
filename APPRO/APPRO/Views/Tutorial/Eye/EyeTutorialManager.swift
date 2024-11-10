//
//  EyeTutorialManager.swift
//  APPRO
//
//  Created by 정상윤 on 11/7/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

final class EyeTutorialManager: TutorialManager {
    
    typealias EntityTargetTapGestureValue = EntityTargetValue<SpatialTapGesture.Value>
    
    let attachmentViewID = "TutorialAttachmentView"
    
    private let headTracker = HeadTracker()
    private let patchDisappearAnimationDuraction = 1.0
    
    private let patchEntityName = "patch"
    
    private(set) var eyeEntity: Entity?
    private var patchEntity: Entity?
    private var attachmentView: Entity?
    
    init() {
        super.init(stretching: .eyes)
    }
    
    func addEyeAndPatchEntity(content: RealityViewContent) async {
        await loadEntities()
        
        if let eyeEntity, let patchEntity {
            configureEyeEntity()
            configurePatchEntity()
            
            content.add(eyeEntity)
            content.add(patchEntity)
        }
    }
    
    func handleTapGestureValue(_ value: EntityTargetTapGestureValue) {
        if let patchEntity,
           value.entity.name == patchEntity.name {
            step1()
        }
    }
    
    func addAttachmentView(content: RealityViewContent, attachments: RealityViewAttachments) {
        guard let attachmentView = attachments.entity(for: attachmentViewID) else {
            dump("addAttachmentView failed: \(attachmentViewID) not found in attachments")
            return
        }
        setClosureComponent(
            entity: attachmentView,
            distance: .attachment,
            upward: 0.01,
            forwardDirection: .positiveZ
        )
        content.add(attachmentView)
        self.attachmentView = attachmentView
    }
    
    private func step1() {
        guard let patchEntity else {
            dump("step1() failed: patchEntity not found!")
            return
        }
        playPatchOpacityAnimation(patchEntity)
        playEyeLoopAnimation()
        completeCurrentStep()
    }
    
    func step2() {
        guard let eyeEntity else { return }
        guard let attachmentView else { return }
        
        eyeEntity.components.remove(ClosureComponent.self)
        attachmentView.components.remove(ClosureComponent.self)
        
        completeCurrentStep()
    }
    
}

private extension EyeTutorialManager {
    
    func loadEntities() async {
        eyeEntity = await loadEntity(entityType: .eyes)
        patchEntity = await loadEntity(entityType: .patch)
    }
    
    func playPatchOpacityAnimation(_ patch: Entity) {
        let opacityAnimationDefinition = FromToByAnimation(from: Float(1.0), to: Float(0.0), bindTarget: .opacity)
        
        do {
            let animationResource = try AnimationResource.generate(with: opacityAnimationDefinition)
            patch.playAnimation(animationResource, transitionDuration: patchDisappearAnimationDuraction)
        } catch {
            dump("playPatchOpacityAnimation failed: \(error)")
        }
    }
    
    func playEyeLoopAnimation() {
        guard let eyeEntity,
              let animationResource = eyeEntity.availableAnimations.first?.repeat() else {
            dump("playEyeLoopAnimation failed: Missing eye entity or availbale animations")
            return
        }
        eyeEntity.playAnimation(animationResource)
    }
    
    func loadEntity(entityType: EntityType) async -> Entity? {
        do {
            return try await Entity(named: entityType.rawValue, in: realityKitContentBundle)
        } catch {
            dump(error)
            return nil
        }
    }
    
    func configureEyeEntity() {
        guard let eyeEntity else {
            dump("configureEyeEntity failed: Missing eyeEntity")
            return
        }
        setClosureComponent(entity: eyeEntity, distance: .eyes)
    }
    
    func configurePatchEntity() {
        guard let patchEntity else {
            dump("configurePatchEntity failed: Missing patchEntity")
            return
        }
        patchEntity.name = patchEntityName
        setClosureComponent(entity: patchEntity, distance: .patch)
        patchEntity.components.set(HoverEffectComponent(.highlight(.default)))
    }
    
    func setClosureComponent(
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
    
}

private enum EntityType: String {
    
    case eyes = "Eye/eyes_loop.usd"
    case ring = "Eye/eye_ring.usd"
    case patch = "Eye/patch.usd"
    case chicken = "Eye/chicken.usd"
    case attachment
    
}

private extension Float {
    
    static let eyes = Float(2.0)
    static let patch = Float(1.8)
    static let attachment = Float(2.05)
    
}
