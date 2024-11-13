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
    
    private(set) var attachmentView = Entity()
    
    init() {
        super.init(stretching: .eyes)
    }
    
    func loadEntities() async -> Bool {
        do {
            eyesEntity = try await loadEntity(entityType: .eyes)
            chickenEntity = try await loadEntity(entityType: .chicken)
            
            return true
        } catch {
            dump("loadEntities failed: \(error)")
            
            return false
        }
    }
    
    func step1() {
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
        completeCurrentStep()
    }
    
    func step2() {
        eyesEntity.components.remove(ClosureComponent.self)
        attachmentView.components.remove(ClosureComponent.self)
        
        completeCurrentStep()
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
            definition: FromToByAnimation(from: 0.0, to: 1.0, bindTarget: .opacity),
            duration: 1.0
        )
    }
    
    @discardableResult
    func playDisappearAnimation(entity: Entity) -> AnimationPlaybackController? {
        playAnimation(
            entity: entity,
            definition: FromToByAnimation(from: 1.0, to: 0.0, bindTarget: .opacity),
            duration: 1.0
        )
    }
    
        
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
