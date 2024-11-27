//
//  EyeStretchingViewModel.swift
//  APPRO
//
//  Created by 정상윤 on 11/23/24.
//

import Combine
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
    
    private var currentDisturbEntityIndex = 0
    
    var currentDisturbEntity: EyeStretchingDisturbEntity? {
        guard disturbEntities.indices.contains(currentDisturbEntityIndex) else {
            return nil
        }
        
        return disturbEntities[currentDisturbEntityIndex]
    }
    
    private var currentDisturbEntityOnEnded = false
    
    private var cancellableBag: Set<AnyCancellable> = []
    
    func makeDoneCountZero() {
        doneCount = 0
        
        currentDisturbEntityIndex = 0
        stretchingPhase = .start
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
        Task {
            do {
                try eyesEntity.removePatch()
                try eyesEntity.playLoopAnimation()
                attachmentView.components.remove(ClosureComponent.self)
                
                try await Task.sleep(nanoseconds: 1_000_000_000)
                stretchingPhase = .ready
            } catch {
                dump("patchTapped failed: \(error)")
            }
        }
    }
    
    func addAttachmentView(content: RealityViewContent, attachments: RealityViewAttachments) throws {
        guard let attachmentView = attachments.entity(for: attachmentViewID) else {
            throw EntityError.entityNotFound(name: attachmentViewID)
        }
        
        self.attachmentView = attachmentView
        content.add(attachmentView)
    }
    
    func handleLongPressingUpdate(value isLongPressing: Bool) {
        guard let currentDisturbEntity,
              currentDisturbEntityOnEnded == false else { return }
        
        if isLongPressing {
            currentDisturbEntity.enlarge()
        } else {
            currentDisturbEntity.reduce()
        }
    }
    
    func handleCurrentDisturbEntityIndexChanged() {
        let prevEntity = disturbEntities[safe: currentDisturbEntityIndex-1]
        let currentEntity = currentDisturbEntity
        
        Task { @MainActor in
            do {
                prevEntity?.disappear()
                try await Task.sleep(nanoseconds: 7 * 100_000_000)
                currentEntity?.appear()
                currentDisturbEntityOnEnded = false
            } catch {
                dump("handleCurrentDisturbEntityIndexChanged failed: \(error)")
            }
        }
    }
    
    private func initializeDisturbEntities() async throws {
        let disturbEntities: [EyeStretchingDisturbEntity] = try await withThrowingTaskGroup(
            of: EyeStretchingDisturbEntity.self
        ) { [weak self] taskGroup in
            DisturbEntityType.allCases.forEach { type in
                taskGroup.addTask { @MainActor in
                    let disturbEntity = EyeStretchingDisturbEntity()
                    try await disturbEntity.loadCoreEntity(type: type)
                    try self?.configureDisturbEntity(type: type, entity: disturbEntity)
                    return disturbEntity
                }
            }
            var entities: [EyeStretchingDisturbEntity] = []
            
            for try await entity in taskGroup {
                entities.append(entity)
                entities.append(entity.clone(recursive: true))
            }
            return entities.shuffled()
        }
        self.disturbEntities = disturbEntities
    }
    
    private func configureDisturbEntity(
        type: DisturbEntityType,
        entity: EyeStretchingDisturbEntity
    ) throws {
        entity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        entity.components.set(HoverEffectComponent(.spotlight(.default)))
        
        try entity.setGestureComponent(
            type: type,
            component: LongPressGestureComponent { [weak self] in
                self?.doneCount += 1
                self?.currentDisturbEntityIndex += 1
                self?.currentDisturbEntityOnEnded = true
            }
        )
    }
    
    func handleEyeRingCollisionState() {
        ringEntity.collisionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self,
                      let currentDisturbEntity else { return }
                
                if state.eyesAreInside {
                    currentDisturbEntity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
                } else {
                    currentDisturbEntity.components.remove(InputTargetComponent.self)
                }
            }
            .store(in: &cancellableBag)
    }
    
}

private extension Array where Element: EyeStretchingDisturbEntity {
    
    subscript(safe index: Int) -> Element? {
        guard self.indices.contains(index) else { return nil }
        
        return self[index]
    }
    
}
