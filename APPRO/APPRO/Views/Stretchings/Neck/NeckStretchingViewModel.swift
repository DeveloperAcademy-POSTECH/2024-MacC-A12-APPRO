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
final class NeckStretchingViewModel: StretchingCounter {
    
    let tutorialAttachmentViewID = "TutorialAttachmentView"
    let stretchingAttachmentViewID = "StretchingAttachmentView"
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
    var doneTimerCheck: [String] = []
    var twoWayStretchingCompletionStatus = [false, false]
    
    var doneCount: Int = 0
    var maxCount: Int = StretchingPart.neck.maxCount
    
    var direction : NeckStretchingDirection = .vertical
    var criteriaTransform : simd_float4x4 = .init()
    
    let soundHelper = SoundEffectHelper<NeckSoundEffects>()
    
    var timerFiveProgressChecker = [true, true, true, true, true]
    
    func loadEntities() async throws {
        pigEntity = try await loadEntity(entityType: .pig)
        pigEntity.name = "pig"
        
        coinEntity = try await loadEntity(entityType: .coin)
        coinEntity.name = "coin"
        
        timerEntity = try await loadEntity(entityType: .timer)
    }
    
    private func loadEntity(entityType: NeckStretchingEntityType) async throws -> Entity {
        return try await Entity(named: entityType.url, in: realityKitContentBundle)
    }
    
    func addTutorialAttachmentView( _ attachments: RealityViewAttachments) {
        guard let attachmentView = attachments.entity(for: tutorialAttachmentViewID) else {
            print("addTutorialAttachmentView failed: \(tutorialAttachmentViewID) not found in attachments" )
            return
        }
        
        self.attachmentView = attachmentView
    }
    
    func addStretchingAttachmentView(_ attachments: RealityViewAttachments) {
        guard let attachmentView = attachments.entity(for: stretchingAttachmentViewID) else {
            print("addStretchingAttachmentView failed: \(stretchingAttachmentViewID) not found in attachments")
            return
        }
        self.attachmentView = attachmentView
    }
    
    func adjustAttachmentViewLocation(_ content: RealityViewContent) {
        updateDeviceHeight()
        attachmentView.transform.translation = .init(x: -0.5, y: startingHeight + 0.4, z: -2.2)
        content.add(attachmentView)
    }
    
    func configureInitialSettingToPig() {
        pigEntity.name = "pig"
        pigEntity.components[InputTargetComponent.self] = InputTargetComponent(allowedInputTypes: .indirect)
        pigEntity.components.set(HoverEffectComponent(.highlight(.default)))
        
        guard let animationResource = pigEntity.availableAnimations.first?.repeat() else { return }
        pigEntity.playAnimation(animationResource)
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
    
    func makeSemiCircleWithCoins(requireRealTimeAnchorInfo:Bool = true) {

        let isVertical = direction == .vertical
        guard let realTimeTransform = self.headTracker.originFromDeviceTransform() else { return }
        
        var transform: simd_float4x4 = .init()
        
        if requireRealTimeAnchorInfo {
            criteriaTransform = realTimeTransform
            transform = realTimeTransform
        } else {
            transform = criteriaTransform
        } 
        
        let translations: [Float3] = drawSemiCirclePoints(transform: transform, isVertical: isVertical, steps: guidingEntitiesCount)
        
        // 좌우방향 스트레칭은 위아래방향과 다르게 가동범위가 넓게 설정해주어야한다.
        let startingTimerIndex = isVertical ? 2 : 1
        let endingTimerIndex = isVertical ? translations.count - 3 : translations.count - 2
        
        for (index, translation) in translations.enumerated() { // 각도조절을 위해서, 180도의 양 끝단에 있는 포인트(0도, 180도)는 사용하지 않는다.
            if index < startingTimerIndex ||  endingTimerIndex < index {
                continue
            }
            
            // 좌우방향 스트레칭의 경우, 별이 +2개 되었으므로 타이머 바로 옆의 배치는 피해준다. 
            if !isVertical {
                if [startingTimerIndex + 1, endingTimerIndex - 1].contains(index) {
                    continue
                }
            }
            
            if index == startingTimerIndex || index == endingTimerIndex {
                let timer = timerEntity.clone(recursive: true)
                timer.look(at: transform.translation(), from: translation, relativeTo: nil, forward: .positiveZ)
                timer.name = "timer_\(index + 1)"
                
                // 타이머가 방향을 가진 모델이라, 스트레칭 방향이 위아래, 좌우인지에 따라서 오브젝트의 배치 방향에 회전을 줘야한다.
                if isVertical {
                    if index == endingTimerIndex {
                        timer.transform.rotation *= simd_quatf(angle: .pi, axis: simd_float3(0,0,1))
                    }
                }else {
                    if index == endingTimerIndex {
                        timer.transform.rotation *= simd_quatf(angle: +.pi / 2 , axis: simd_float3(0,0,1))
                    } else {
                        timer.transform.rotation *= simd_quatf(angle: -.pi / 2 , axis: simd_float3(0,0,1))
                    }
                }
                
                coinEntities.append(timer)
            } else {
                let coin = coinEntity.clone(recursive: true)
                coin.look(at: transform.translation(), from: translation, relativeTo: nil, forward: .positiveZ)
                coin.name = "coin_\(index + 1)"
                coinEntities.append(coin)
            }
        }
    }
    
    func resetCoins(currentLocationBased: Bool = true) {
        for coin in coinEntities {
            coin.removeFromParent()
        }
        
        coinEntities.removeAll()
        makeSemiCircleWithCoins(requireRealTimeAnchorInfo: currentLocationBased)
    }
    
    func disableAllCoins() {
        for coin in coinEntities {
            coin.isEnabled = false
        }
    }
    
    func enableAllCoins() {
        for coin in coinEntities {
            coin.isEnabled = true
        }
    }
    
    func makeDoneCountZero() {
        doneCount = 0
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
    
    mutating func setZeroForBothBounds() {
        self.upperBoundIndex = 0
        self.lowerBoundIndex = 0
    }
}
