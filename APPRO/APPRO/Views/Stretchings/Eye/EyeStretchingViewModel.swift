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
    
    var stretchingPhase: EyeStretchingPhase = .waiting
    
    private(set) var eyesEntity = EyeStretchingEyesEntity()
    private(set) var ringEntity = EyeStretchingRingEntity()
    private(set) var monitorEntity = Entity()
    private(set) var disturbEntities: [EyeStretchingDisturbEntity] = []
    private(set) var attachmentView = Entity()
    
    func makeDoneCountZero() {
        doneCount = 0
    }
    
    func loadEntities() async throws {
        try await eyesEntity.loadCoreEntity()
        try await ringEntity.loadCoreEntity()
        monitorEntity = try await Entity(
            named: EyeStretchingEntityType.monitor.loadURL,
            in: realityKitContentBundle
        )
        try await initializeDisturbEntities()
    }
    
    func patchTapped() {
        do {
            try eyesEntity.removePatch()
            try eyesEntity.playLoopAnimation()
            attachmentView.components.remove(ClosureComponent.self)
            stretchingPhase = .ready
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
    
    private func initializeDisturbEntities() async throws {
        let disturbEntities: [EyeStretchingDisturbEntity] = try await withThrowingTaskGroup(
            of: EyeStretchingDisturbEntity.self
        ) { taskGroup in
            DisturbEntityType.allCases.forEach { type in
                taskGroup.addTask { @MainActor in
                    let disturbEntity = EyeStretchingDisturbEntity()
                    try await disturbEntity.loadCoreEntity(type: type)
                    return disturbEntity
                }
            }
            var entities: [EyeStretchingDisturbEntity] = []
            
            for try await entity in taskGroup {
                entities.append(entity)
                entities.append(entity.clone(recursive: true))
            }
            return entities
        }
        self.disturbEntities = disturbEntities
    }
    
}
