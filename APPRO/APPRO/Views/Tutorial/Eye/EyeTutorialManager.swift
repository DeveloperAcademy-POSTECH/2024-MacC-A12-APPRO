//
//  EyeTutorialManager.swift
//  APPRO
//
//  Created by 정상윤 on 11/7/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Combine

final class EyeTutorialManager: TutorialManager {
    
    let attachmentViewID = "TutorialAttachmentView"
    
    private let headTracker = HeadTracker()
    private var cancellableBag: Set<AnyCancellable> = []
    private let patchDisappearAnimationDuraction = 1.0
    
    private(set) var eyeEntity = Entity()
    private(set) var chickenEntity = Entity()
    private(set) var attachmentView = Entity()
    
    var patchEntity: Entity? {
        eyeEntity.findEntity(named: "patch")
    }
    
    init() {
        super.init(stretching: .eyes)
    }
    
    func step1() {
        playPatchDisappearAnimation()
        playEyeLoopAnimation(entity: eyeEntity)
        completeCurrentStep()
    }
    
    func step2() {
        eyeEntity.components.remove(ClosureComponent.self)
        attachmentView.components.remove(ClosureComponent.self)
        
        completeCurrentStep()
    }
    
}

// MARK: - Adding Entities to RealityViewContent Methods

extension EyeTutorialManager {
    
    func addEyeAndPatchEntity(content: RealityViewContent) async {
        do {
            eyeEntity = try await loadEntity(entityType: .eyes)
        } catch {
            dump("addEyeAndPatchEntity failed: \(error)")
        }
        
        configureEyeEntity(entity: eyeEntity)
        configurePatchEntity(eyeEntity: eyeEntity)
        
        content.add(eyeEntity)
    }
    
    func addChickenEntity(content: RealityViewContent) async {
        do {
            chickenEntity = try await loadEntity(entityType: .chicken)
        } catch {
            dump("addChickenEntity failed: \(error)")
        }
        
        configureChickenEntity(entity: chickenEntity)
        content.add(chickenEntity)
        playOpacityAnimation(
            entity: chickenEntity,
            from: 0.0, to: 1.0,
            duration: patchDisappearAnimationDuraction
        )
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

extension EyeTutorialManager {
    
    func playPatchDisappearAnimation() {
        guard let patchEntity else { return }
        
        let playbackController = playOpacityAnimation(
            entity: patchEntity,
            from: 1.0,
            to: 0.0,
            duration: patchDisappearAnimationDuraction
        )
        
        patchEntity.scene?.publisher(for: AnimationEvents.PlaybackCompleted.self)
            .filter { $0.playbackController == playbackController }
            .sink(receiveValue: { _ in
                patchEntity.removeFromParent()
            })
            .store(in: &cancellableBag)
    }
    
    func playOpacityAnimation(
    
    @discardableResult
    private func playOpacityAnimation(
        entity: Entity,
        from: Float,
        to: Float,
        duration: TimeInterval
    ) -> AnimationPlaybackController? {
        let opacityAnimationDefinition = FromToByAnimation(from: from, to: to, bindTarget: .opacity)
        
        return playAnimation(entity: entity, definition: opacityAnimationDefinition, duration: duration)
    }
    
    private func playEyeLoopAnimation(entity: Entity) {
        guard let animationResource = entity.availableAnimations.first?.repeat() else {
            dump("playEyeLoopAnimation failed: No availbale animations")
            return
        }
        entity.playAnimation(animationResource)
    }
    
    @discardableResult
    private func playAnimation(
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
    
    func loadEntity(entityType: EntityType) async throws -> Entity {
        return try await Entity(named: entityType.rawValue, in: realityKitContentBundle)
    }
    
    func configureEyeEntity(entity: Entity) {
        setClosureComponent(entity: entity, distance: .eyes)
    }
    
    func configurePatchEntity(eyeEntity: Entity) {
        guard let patchEntity = eyeEntity.findEntity(named: "patch") else {
            dump("configurePatchEntity failed: patch not found in eyeEntity")
            return
        }
        patchEntity.components.set(HoverEffectComponent(.highlight(.default)))
    }
    
    func configureChickenEntity(entity: Entity) {
        entity.name = chickenEntityName
        entity.setPosition(.init(x: 2, y: 0, z: 0), relativeTo: eyeEntity)
        entity.components.set(OpacityComponent(opacity: 0.0))
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
    
    case eyes = "Eye/eyes_with_patch.usd"
    case ring = "Eye/eye_ring.usd"
    case chicken = "Eye/chicken.usd"
    case attachment
    
}

private extension Float {
    
    static let eyes = Float(2.0)
    static let attachment = Float(2.05)
    
}
