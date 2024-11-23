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
    
    private(set) var eyesEntity = EyeStretchingEyesEntity()
    private(set) var chickenEntity = EyeStretchingDisturbEntity()
    private(set) var ringEntity = EyeStretchingRingEntity()
    private(set) var monitorEntity = Entity()
    
    private(set) var attachmentView = Entity()
    
    private var originalChickenScale: Float3 = .init()
    private var largeChickenScale: Float3 {
        originalChickenScale * 1.5
    }
    
    private var longPressGestureOnEnded = false
    
    init() {
        super.init(stretching: .eyes)
    }
    
    func loadEntities() async -> Bool {
        do {
            try await eyesEntity.loadCoreEntity()
            try await ringEntity.loadCoreEntity()
            try await chickenEntity.loadCoreEntity(type: .chicken)
            monitorEntity = try await loadEntity(entityType: .monitor)
            
            return true
        } catch {
            dump("loadEntities failed: \(error)")
            
            return false
        }
    }
    
    func step1Done() {
        do {
            try eyesEntity.removePatch()
            try eyesEntity.playLoopAnimation()
        } catch {
            dump("step1Done error occured: \(error)")
        }
        advanceToNextStep()
    }
    
    func handleLongPressingUpdate(value isLongPressing: Bool) {
        guard longPressGestureOnEnded == false else { return }
        
        if isLongPressing {
            chickenEntity.enlarge()
        } else {
            chickenEntity.reduce()
        }
    }
    
    func longPressOnEnded() {
        longPressGestureOnEnded = true
        chickenEntity.disappear()
        advanceToNextStep()
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
    
    private func playEyeLoopAnimation(entity: Entity) {
        guard let animationResource = eyesEntity.availableAnimations.first?.repeat() else {
            dump("playEyeLoopAnimation failed: No availbale animations")
            return
        }
        eyesEntity.playAnimation(animationResource)
    }
    
}
