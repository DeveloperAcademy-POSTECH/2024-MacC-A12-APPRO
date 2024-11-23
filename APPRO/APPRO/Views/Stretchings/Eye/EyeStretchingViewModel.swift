//
//  EyeStretchingViewModel.swift
//  APPRO
//
//  Created by 정상윤 on 11/23/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

@MainActor
@Observable
final class EyeStretchingViewModel: StretchingCounter {
    
    var doneCount = 0
    let maxCount = 12
    
    let attachmentViewID = "StretchingAttachmentView"
    
    let headTracker = HeadTracker()
    
    private(set) var stretchingPhase: EyeStretchingPhase = .waiting
    
    private(set) var eyesEntity = EyeStretchingEyesEntity()
    private(set) var ringEntity = EyeStretchingRingEntity()
    private(set) var attachmentView = Entity()
    
    func makeDoneCountZero() {
        doneCount = 0
    }
    
    func loadEntities() async throws {
        try await eyesEntity.loadCoreEntity()
        try await ringEntity.loadCoreEntity()
    }
    
    func patchTapped() {
        do {
            try eyesEntity.removePatch()
            try eyesEntity.playLoopAnimation()
            attachmentView.components.remove(ClosureComponent.self)
            stretchingPhase = .started
        } catch {
            dump("patchTapped failed: \(error)")
        }
    }
    
    func addAttachmentView(content: RealityViewContent, attachments: RealityViewAttachments) throws {
        guard let attachmentView = attachments.entity(for: attachmentViewID) else {
            throw EntityError.entityNotFound(name: attachmentViewID)
        }
        
        self.attachmentView = attachmentView
        content.add(attachmentView)
    }
    
}
