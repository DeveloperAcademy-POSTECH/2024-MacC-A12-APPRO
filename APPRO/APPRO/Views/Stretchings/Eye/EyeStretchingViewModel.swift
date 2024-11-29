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
    private(set) var disturbObjects: [EyeStretchingDisturbObject] = []
    private(set) var attachmentView = Entity()
    
    private var currentDisturbObjectIndex = 0
    
    var currentDisturbObject: EyeStretchingDisturbObject? {
        guard disturbObjects.indices.contains(currentDisturbObjectIndex) else {
            return nil
        }
        
        return disturbObjects[currentDisturbObjectIndex]
    }
    
    private var currentDisturbEntityOnEnded = false
    
    private var cancellableBag: Set<AnyCancellable> = []
    
    func makeDoneCountZero() {
        doneCount = 0
        
        currentDisturbObjectIndex = 0
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
        guard let currentDisturbObject,
              currentDisturbEntityOnEnded == false else { return }
        
        if isLongPressing {
            currentDisturbObject.enlarge()
        } else {
            currentDisturbObject.reduce()
        }
    }
    
    func handleCurrentDisturbEntityIndexChanged() {
        let prevEntity = disturbObjects[safe: currentDisturbObjectIndex-1]
        let currentEntity = currentDisturbObject
        
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
        let disturbObjects: [EyeStretchingDisturbObject] = try await withThrowingTaskGroup(
            of: EyeStretchingDisturbObject.self
        ) { [weak self] taskGroup in
            DisturbEntityType.allCases.forEach { type in
                taskGroup.addTask { @MainActor in
                    let disturbObject = EyeStretchingDisturbObject(type: type)
                    try await disturbObject.loadEntity()
                    try disturbObject.setGestureComponent(
                        LongPressGestureComponent { [weak self] in
                            self?.doneCount += 1
                            self?.currentDisturbObjectIndex += 1
                            self?.currentDisturbEntityOnEnded = true
                    })
                    return disturbObject
                }
            }
            var objects: [EyeStretchingDisturbObject] = []
            
            for try await object in taskGroup {
                objects.append(object)
                objects.append(object.clone)
            }
            return objects.shuffled()
        }
        self.disturbObjects = disturbObjects
    }
    
    func handleEyeRingCollisionState() {
        ringEntity.collisionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self,
                      let currentDisturbObject else { return }
                
                if state.eyesAreInside {
                    currentDisturbEntity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
                } else {
                    currentDisturbEntity.components.remove(InputTargetComponent.self)
                }
            }
            .store(in: &cancellableBag)
    }
    
}

private extension Array where Element: EyeStretchingDisturbObject {
    
    subscript(safe index: Int) -> Element? {
        guard self.indices.contains(index) else { return nil }
        
        return self[index]
    }
    
}
