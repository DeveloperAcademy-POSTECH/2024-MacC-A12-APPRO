//
//  NeckTutorialViewModel.swift
//  APPRO
//
//  Created by marty.academy on 11/21/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

@Observable
@MainActor
final class NeckTutorialViewModel {
    
    let attachmentViewID = "TutorialAttachmentView"
    let headTracker = HeadTracker()
    
    private(set) var pigEntity = Entity()
    private(set) var coinEntity = Entity()
    private(set) var timerEntity = Entity()
    
    private(set) var attachmentView = Entity()
    
    private var zDistanceToPig: Float = .zDistanceToPig // TODO: pinch 할 때에 사용자 디바이스 y 값으로 변경.
    
    func loadEntities() async -> Bool {
        do {
            pigEntity = try await loadEntity(entityType: .pig)
            coinEntity = try await loadEntity(entityType: .coin)
//            timerEntity = try await loadEntity(entityType: .timer) TODO: add timer entity later
            return true
        } catch {
            print("loadEntities failed: \(error)")
            return false
        }
    }
    
    private func loadEntity(entityType: NeckStretchingEntityType) async throws -> Entity {
        return try await Entity(named: entityType.url, in: realityKitContentBundle)
    }
    
    func addAttachmentView(_ content: RealityViewContent, _ attachments: RealityViewAttachments) {
        guard let attachmentView = attachments.entity(for: attachmentViewID) else {
            print("addAttachmentView failed: \(attachmentViewID) not found in attachments" )
            return
        }
        content.add(attachmentView)
        self.attachmentView = attachmentView
    }
    
    func locatedPigOnFixedLocation() {
        guard let currentTransform = self.headTracker.originFromDeviceTransform() else { return }
        
        let y = currentTransform.translation().y
        pigEntity.transform.translation = .init(x: 0, y: y , z: -2.0)
    }
    
    func configurePigEntity() {
        setClosureComponent(entity: pigEntity, distance: .zDistanceToPig)
    }
    
    private func setClosureComponent(
        entity: Entity,
        distance: Float,
        forwardDirection: Entity.ForwardDirection = .positiveZ
    ) {
        let closureComponent = ClosureComponent { [weak self] deltaTiem in
            guard let currentTransform = self?.headTracker.originFromDeviceTransform() else { return }
            
            let currentTranslation = currentTransform.translation()
            let targetPosition = currentTranslation - distance * currentTransform.forward()
            entity.look(at: currentTranslation, from: targetPosition, relativeTo: nil, forward: forwardDirection)
            // FIXME: 사용자 디바이스 쪽으로 바라보고 있지 않는다면,  target - currentTranslation vector 로 변경 가능.
            
        }
        entity.components.set(closureComponent)
    }
    
}

private extension Float {
    static let zDistanceToPig = Float(2.0)
}
