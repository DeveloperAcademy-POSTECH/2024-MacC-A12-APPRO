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
    
    var coinEntities: [Entity] = []
    
    private(set) var attachmentView = Entity()
    
    var timerController: AnimationPlaybackController?
    
    private var zDistanceToPig: Float = .zDistanceToPig // TODO: pinch 할 때에 사용자 디바이스 y 값으로 변경.
    
    var startingHeight: Float = 0.0

    var guidingEntitiesCount : Int = 15
    
    var firstCollisionEventHappend = false
    var collisionBound = AvailableCollisionBound()
    
    var completionStatusArray = [false, false]
    
    func loadEntities() async -> Bool {
        do {
            pigEntity = try await loadEntity(entityType: .pig)
            pigEntity.name = "pig"
            
            coinEntity = try await loadEntity(entityType: .coin)
            coinEntity.name = "coin"
            
            timerEntity = try await loadEntity(entityType: .timer)
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
    
    func adjustAttachmentViewLocation() {
        updateDeviceHeight()
        attachmentView.transform.translation = .init(x: -0.5, y: startingHeight + 0.4, z: -2.2)
    }
    
    func configureInitialSettingToPig() {
        pigEntity.name = "pig"
        pigEntity.components[InputTargetComponent.self] = InputTargetComponent(allowedInputTypes: .indirect)
        pigEntity.components.set(HoverEffectComponent(.highlight(.default)))
    }
    
    func locatedPigOnFixedLocation() {
        updateDeviceHeight()
        pigEntity.transform.translation = .init(x: 0, y: startingHeight , z: -startingHeight)
    }
    
    func configureDeviceTrackingToPigEntity() {
        setClosureComponent(entity: pigEntity, distance: startingHeight)
    }
    
    // TODO: startingHeight 값이 왔다리 갔다리 한다. 디바이스 착용, 테스트해서 확인 작업이 필요하다.
    func updateDeviceHeight() {
        guard let currentTransform = self.headTracker.originFromDeviceTransform() else { return }
        let y = currentTransform.translation().y
        startingHeight = y
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
    
    func addCoinEntity(_ content: RealityViewContent) {
        for coin in coinEntities {
            content.add(coin)
        }
    }
    
    func makeSemiCircleWithCoins() {
        guard let transform = self.headTracker.originFromDeviceTransform() else { return }
        let translations: [Float3] = drawSemiCirclePoints(transform: transform, isVertical: true, steps: guidingEntitiesCount)
        
        let startingTimerIndex = 2
        let endingTimerIndex = translations.count - 3
        
        for (index, translation) in translations.enumerated() { // 각도조절을 위해서, 180도의 양 끝단에 있는 포인트(0도, 180도)는 사용하지 않는다.
            
            if index < startingTimerIndex ||  endingTimerIndex < index {
                continue
            }
            
            if index == startingTimerIndex || index == endingTimerIndex {
                let timer = timerEntity.clone(recursive: true)
                timer.look(at: transform.translation(), from: translation, relativeTo: nil, forward: .positiveZ)
                timer.name = "timer_\(index + 1)"
                coinEntities.append(timer)
            } else {
                let coin = coinEntity.clone(recursive: true)
                coin.look(at: transform.translation(), from: translation, relativeTo: nil, forward: .positiveZ)
                coin.name = "coin_\(index + 1)"
                coinEntities.append(coin)
            }
        }
    }
    
    func resetCoins() {
        for coin in coinEntities {
            coin.removeFromParent()
        }
        coinEntities.removeAll()
        
        makeSemiCircleWithCoins()
    }
}

private extension Float {
    static let zDistanceToPig = Float(2.0)
}

enum localAxis {
    case x, y, z
}

struct AvailableCollisionBound {
    var upperBoundIndex : Int = 0
    var lowerBoundIndex : Int = 0
}
