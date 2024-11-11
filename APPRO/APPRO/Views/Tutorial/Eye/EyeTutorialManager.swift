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
    
    private let eyeEntityName = "eyes_capsule"
    private let patchEntityName = "patch"
    
    private var eyeEntity: Entity?
    private var patchEntity: Entity?
    private var attachmentView: Entity?
    
    private var animationPlaybackController: AnimationPlaybackController?
    
    init() {
        super.init(stretching: .eyes)
        
        Task {
            eyeEntity = await loadEntity(entityType: .eyes)
            patchEntity = await loadEntity(entityType: .patch)
        }
    }
    
    func handleTapGestureValue(_ value: EntityTargetTapGestureValue) {
        if let patchEntity,
           value.entity.name == patchEntity.name {
            step1()
        }
    }
    
    private func step1() {
        guard let patchEntity else {
            dump("step1() failed: patchEntity not found!")
            return
        }
        
        guard let eyeEntity else {
            dump("step1() failed: eyeEntity not found!")
            return
        }
        playOpacityAnimation(entity: patchEntity, from: 1.0, to: 0.0)
        playEyeLoopAnimation(entity: eyeEntity)
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

// MARK: - Adding Entities to RealityViewContent Methods

extension EyeTutorialManager {
    
    func addEyeAndPatchEntity(content: RealityViewContent) {
        if let eyeEntity, let patchEntity {
            configureEyeEntity(entity: eyeEntity)
            configurePatchEntity(entity: patchEntity)
            
            content.add(eyeEntity)
            content.add(patchEntity)
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
    
}

// MARK: - Animation Methods

private extension EyeTutorialManager {
    
    func playOpacityAnimation(
        entity: Entity,
        from: Float,
        to: Float
    ) {
        let opacityAnimationDefinition = FromToByAnimation(from: from, to: to, bindTarget: .opacity)
        
        do {
            let animationResource = try AnimationResource.generate(with: opacityAnimationDefinition)
            entity.playAnimation(animationResource, transitionDuration: patchDisappearAnimationDuraction)
        } catch {
            dump("playOpacityAnimation failed: \(error)")
        }
    }
    
    func playEyeLoopAnimation(entity: Entity) {
        guard let animationResource = entity.availableAnimations.first?.repeat() else {
            dump("playEyeLoopAnimation failed: No availbale animations")
            return
        }
        entity.playAnimation(animationResource)
    }
    
    @discardableResult
    func playAnimation(
        entity: Entity,
        definition: AnimationDefinition,
        duration: TimeInterval
    ) -> AnimationPlaybackController? {
        do {
            let resource = try AnimationResource.generate(with: definition)
            return entity.playAnimation(resource, transitionDuration: duration)
        } catch {
            dump(error)
            return nil
        }
    }
    
}

// MARK: - Entity Configuration & Load Methods

private extension EyeTutorialManager {
    
    func loadEntity(entityType: EntityType) async -> Entity? {
        do {
            return try await Entity(named: entityType.rawValue, in: realityKitContentBundle)
        } catch {
            dump(error)
            return nil
        }
    }
    
    func configureEyeEntity(entity: Entity) {
        setClosureComponent(entity: entity, distance: .eyes)
    }
    
    func configurePatchEntity(entity: Entity) {
        entity.name = patchEntityName
        setClosureComponent(entity: entity, distance: .patch)
        entity.components.set(HoverEffectComponent(.highlight(.default)))
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
