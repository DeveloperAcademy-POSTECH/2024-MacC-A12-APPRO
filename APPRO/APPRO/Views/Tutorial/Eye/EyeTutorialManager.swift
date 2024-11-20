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
    let headTracker = HeadTracker()
    
    private var cancellableBag: Set<AnyCancellable> = []
    
    private(set) var eyesEntity = Entity()
    private(set) var chickenEntity = Entity()
    private(set) var ringEntity = Entity()
    private(set) var monitorEntity = Entity()
    
    private(set) var attachmentView = Entity()
    
    private var originalChickenScale: Float3 = .init()
    private var largeChickenScale: Float3 {
        originalChickenScale * 1.5
    }
    
    private var eyesCollidingInnerPlane = true {
        didSet {
            updateRingEntityParameter(entity: ringEntity)
        }
    }
    private var eyesCollidingRestrictLine = false {
        didSet {
            updateRingEntityParameter(entity: ringEntity)
        }
    }
    
    private var eyesIsInside: Bool {
        eyesCollidingInnerPlane && !eyesCollidingRestrictLine
    }
    
    private var longPressGestureOnEnded = false
    
    init() {
        super.init(stretching: .eyes)
    }
    
    func loadEntities() async -> Bool {
        do {
            eyesEntity = try await loadEntity(entityType: .eyes)
            chickenEntity = try await loadEntity(entityType: .disturbEntity(type: .chicken))
            ringEntity = try await loadEntity(entityType: .ring)
            monitorEntity = try await loadEntity(entityType: .monitor)
            originalChickenScale = chickenEntity.transform.scale
            
            return true
        } catch {
            dump("loadEntities failed: \(error)")
            
            return false
        }
    }
    
    func step1Done() {
        if let patchEntity = eyesEntity.findEntity(named: "patch"),
           let playbackController = playDisappearAnimation(entity: patchEntity) {
            patchEntity.scene?.publisher(for: AnimationEvents.PlaybackCompleted.self)
                .filter { $0.playbackController == playbackController }
                .sink(receiveValue: { _ in
                    patchEntity.removeFromParent()
                })
                .store(in: &cancellableBag)
        }
        playEyeLoopAnimation(entity: eyesEntity)
        advanceToNextStep()
    }
    
    func handleLongPressingUpdate(value isLongPressing: Bool) {
        guard longPressGestureOnEnded == false else { return }
        
        if isLongPressing {
            playEnlargeChickenAnimation(entity: chickenEntity)
        } else {
            playReduceChickenAnimation(entity: chickenEntity)
        }
    }
    
    func handleLongPressOnEnded() {
        longPressGestureOnEnded = true
        playDisappearChickenAnimation(entity: chickenEntity)
        advanceToNextStep()
    }
    
    func subscribeRingCollisionEvent(entity: Entity) {
        guard let innerPlaneEntity = ringEntity.findEntity(named: "inner_plane"),
              let restrictLineEntity = ringEntity.findEntity(named: "restrict_line") else {
            dump("subscribeRingCollisionEvent failed: No innerPlaneEntity or restrictLineEntity found")
            return
        }
        guard let scene = entity.scene else {
            dump("subscribeRingCollisionEvent failed: Scene is not found")
            return
        }
        subscribeEyesInnerPlaneEvent(scene: scene, entity: innerPlaneEntity)
        subscribeEyesRestrictLineEvent(scene: scene, entity: restrictLineEntity)
    }
    
    private func subscribeEyesInnerPlaneEvent(scene: RealityKit.Scene, entity: Entity) {
        scene.subscribe(to: CollisionEvents.Began.self, on: entity) { [weak self] _ in
            self?.eyesCollidingInnerPlane = true
        }
        .store(in: &cancellableBag)
        
        scene.subscribe(to: CollisionEvents.Ended.self, on: entity) { [weak self] _ in
            self?.eyesCollidingInnerPlane = false
        }
        .store(in: &cancellableBag)
    }
    
    private func subscribeEyesRestrictLineEvent(scene: RealityKit.Scene, entity: Entity) {
        scene.subscribe(to: CollisionEvents.Began.self, on: entity) { [weak self] _ in
            self?.eyesCollidingRestrictLine = true
        }
        .store(in: &cancellableBag)
        
        scene.subscribe(to: CollisionEvents.Ended.self, on: entity) { [weak self] _ in
            self?.eyesCollidingRestrictLine = false
        }
        .store(in: &cancellableBag)
    }
    
    private func updateRingEntityParameter(entity: Entity) {
        guard let torusModelEntity = entity.findEntity(named: "Torus") as? ModelEntity else {
            dump("updateRingEntityParameter failed: Torus ModelEntity not found")
            return
        }
        guard var shaderGraphMaterial = torusModelEntity.components[ModelComponent.self]?.materials.first as? ShaderGraphMaterial else {
            dump("updateRingEntityParameter failed: ShaderGraphMaterial not found")
            return
        }
        do {
            try shaderGraphMaterial.setParameter(name: "EyeIsInside", value: .bool(eyesIsInside))
            torusModelEntity.components[ModelComponent.self]?.materials = [shaderGraphMaterial]
        } catch {
            dump("updateRingEntityParameter failed: \(error)")
        }
    }
    
}

// MARK: - Adding Entities to RealityViewContent Methods

extension EyeTutorialManager {
    
    func addAttachmentView(content: RealityViewContent, attachments: RealityViewAttachments) {
        guard let attachmentView = attachments.entity(for: attachmentViewID) else {
            dump("addAttachmentView failed: \(attachmentViewID) not found in attachments")
            return
        }
        
        content.add(attachmentView)
        self.attachmentView = attachmentView
    }
    
    private func loadEntity(entityType: EyeStretchingEntityType) async throws -> Entity {
        return try await Entity(named: entityType.loadURL, in: realityKitContentBundle)
    }
    
}

// MARK: - Animation Methods

extension EyeTutorialManager {
    
    @discardableResult
    func playAppearAnimation(entity: Entity) -> AnimationPlaybackController? {
        playAnimation(
            entity: entity,
            definition: FromToByAnimation(from: Float(0.0), to: Float(1.0), bindTarget: .opacity),
            duration: 1.0
        )
    }
    
    @discardableResult
    func playDisappearAnimation(entity: Entity) -> AnimationPlaybackController? {
        playAnimation(
            entity: entity,
            definition: FromToByAnimation(from: Float(1.0), to: Float(0.0), bindTarget: .opacity),
            duration: 1.0
        )
    }
    
    private func playEnlargeChickenAnimation(entity: Entity) {
        var toTransform = entity.transform
        toTransform.scale = largeChickenScale
        entity.move(to: toTransform, relativeTo: nil)
    }
    
    private func playReduceChickenAnimation(entity: Entity) {
        var toTransform = entity.transform
        toTransform.scale = originalChickenScale
        entity.move(to: toTransform, relativeTo: nil)
    }
    
    private func playDisappearChickenAnimation(entity: Entity) {
        var transform = entity.transform
        transform.scale = .zero
        entity.move(to: transform, relativeTo: nil, duration: 0.5)
    }
    
    private func playEyeLoopAnimation(entity: Entity) {
        guard let animationResource = eyesEntity.availableAnimations.first?.repeat() else {
            dump("playEyeLoopAnimation failed: No availbale animations")
            return
        }
        eyesEntity.playAnimation(animationResource)
    }
    
    @discardableResult
    private func playAnimation(
        entity: Entity,
        definition: AnimationDefinition,
        duration: TimeInterval = 0
    ) -> AnimationPlaybackController? {
        do {
            let resource = try AnimationResource.generate(with: definition)
            return entity.playAnimation(resource, transitionDuration: duration)
        } catch {
            dump("playAnimation failed: \(error)")
            return nil
        }
    }
    
}
