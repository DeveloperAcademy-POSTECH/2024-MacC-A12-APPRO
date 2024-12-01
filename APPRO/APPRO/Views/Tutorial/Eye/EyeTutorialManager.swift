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
    
    private(set) var eyesObject = EyeStretchingEyesObject()
    private(set) var chickenObject = EyeStretchingDisturbObject(type: .chicken)
    private(set) var ringObject = EyeStretchingRingObject()
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
    
    deinit {
        cancellableBag.removeAll()
        debugPrint(self, "deinited")
    }

    func resetAttactmentViewEntity() {
        attachmentView.components.removeAll()
        attachmentView = Entity()
    }

    func loadEntities() async -> Bool {
        do {
            await withThrowingTaskGroup(of: Void.self) { [weak self] taskGroup in
                taskGroup.addTask {
                    try await self?.eyesObject.loadEntity()
                    try await self?.ringObject.loadEntity()
                    try await self?.chickenObject.loadEntity()
                }
            }
            monitorEntity = try await loadEntity(entityType: .monitor)
            
            return true
        } catch {
            dump("loadEntities failed: \(error)")
            return false
        }
    }
    
    func step1Done() {
        do {
            try eyesObject.removePatch()
            try eyesObject.playLoopAnimation()
        } catch {
            dump("step1Done error occured: \(error)")
        }
        advanceToNextStep()
    }
    
    func handleLongPressingUpdate(value isLongPressing: Bool) {
        guard longPressGestureOnEnded == false else { return }
        
        if isLongPressing {
            chickenObject.enlarge()
        } else {
            chickenObject.reduce()
        }
    }
    
    func longPressOnEnded() {
        longPressGestureOnEnded = true
        chickenObject.disappear()
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
        attachmentView.name = "attachmentView"
        content.add(attachmentView)
        self.attachmentView = attachmentView
    }
    
    private func loadEntity(entityType: EyeStretchingEntityType) async throws -> Entity {
        return try await Entity(named: entityType.loadURL, in: realityKitContentBundle)
    }
    
}
