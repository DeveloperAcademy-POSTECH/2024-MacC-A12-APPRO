//
//  ShoulderStretchingView.swift
//  APPRO
//
//  Created by Damin on 10/30/24.
//

import SwiftUI
import RealityKit

struct ShoulderStretchingView: View {
    @State private var viewModel = ShoulderStretchingViewModel()
    @State private var isColliding: Bool = false
    
    var body: some View {
        RealityView { content, attachments in
            content.add(viewModel.contentEntity)
            await viewModel.setEntryRocket()
            viewModel.setHandRocketEntity()
            subscribeToCollisionEvents(content: content)
            viewModel.addAttachmentView(content, attachments)
            viewModel.addShoulderTimerEntity()
        } update: { content, attachments in
            if viewModel.doneCount == viewModel.maxCount {
                viewModel.showEndAttachmentView(content, attachments)
            } else if viewModel.isRetry {
                viewModel.deleteEndAttachmentView(content, attachments)
                viewModel.addAttachmentView(content, attachments)
                
                viewModel.isRetry = false
            } else {
                viewModel.computeTransformHandTracking()
            }
        } attachments: {
            Attachment(id: viewModel.stretchingAttachmentViewID) {
                StretchingAttachmentView(counter: viewModel, stretchingPart: .shoulder)
            }
            
            Attachment(id: viewModel.stretchingFinishAttachmentViewID) {
                StretchingFinishAttachmentView(counter: viewModel, stretchingPart: .shoulder)
            }
        }
        .upperLimbVisibility(.hidden)
        .ignoresSafeArea()
        .task {
            await viewModel.loadStarModelEntity()
        }
        .task {
            await viewModel.startHandTrackingSession()
        }
        .task {
            await viewModel.updateHandTracking()
        }
        .onChange(of: viewModel.halfSetCount, initial: false ) { _, newValue in
            if newValue / 2 <= viewModel.maxCount && newValue != 0{
                if newValue % 2 == 0 {
                    viewModel.doneCount += 1
                }
            }
        }
        .onChange(of: viewModel.doneCount, initial: false ) { oldValue, newValue in
            if newValue < oldValue && newValue == 0 {
                viewModel.isRetry = true
                viewModel.halfSetCount = 0
            }
        }
    }
    
    func subscribeToCollisionEvents(content: RealityViewContent) {
        guard let rightCollisionModel = viewModel.handRocketEntity.findEntity(named: "RocketCollisionModel") as? ModelEntity else { return }
            // 충돌 시작 감지
        _ = content.subscribe(to: CollisionEvents.Began.self, on: rightCollisionModel) { collisionEvent in
            setCollisionAction(collisionEvent: collisionEvent)
        }
        
        // 충돌 종료 감지
        _ = content.subscribe(to: CollisionEvents.Ended.self, on: rightCollisionModel) { collisionEvent in
            handleCollisionEnd(collisionEvent: collisionEvent)
        }
        
        // 애니메이션 종료 감지
        _ = content.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: nil) { animationEvent in
            if animationEvent.playbackController.entity?.name == "EntryRocket" {
                viewModel.entryRocketEntity.removeFromParent()
                viewModel.addRightHandAnchor()
            }else {
                animationEvent.playbackController.entity?.removeFromParent()
                executeCollisionAction()
                viewModel.halfSetCount += 1
            }
        }
    }
    
    func setCollisionAction(collisionEvent: CollisionEvents.Began) {
        
        let collidedModelEntity = collisionEvent.entityB
        
        if collidedModelEntity.name.contains("TimerCollisionModel") && !isColliding {
            viewModel.playCustomAnimation(timerEntity: viewModel.shoulderTimerEntity)
            viewModel.initiateAllTimerProgress()
            isColliding = true
            return
        }
                
        // 충돌시 particle, audio 실행
        viewModel.playEmitter(eventEntity: collidedModelEntity)
        
        if let effect = ShoulderSoundEffects.allCases.first(where: { effect in
            guard let entityNumber = Int(collidedModelEntity.name.dropFirst(4)) else { return false }
            guard let effectNumber = Int(effect.rawValue.dropFirst(4)) else { return false }
            // 나머지를 이용해 숫자를 대응
            return (entityNumber - 1) % ShoulderSoundEffects.stars.count + 1 == effectNumber
        }) {
            viewModel.soundHelper.playSound(effect, on: collidedModelEntity)
        }

        // 다음 엔터티 일때만 Material 변경
        if collidedModelEntity.name == "star\(viewModel.expectedNextNumber)" {
            viewModel.changeMatreialColor(entity: collidedModelEntity)
            viewModel.addExpectedNextNumber()
            
            // 마지막 엔터티 감지
            if collidedModelEntity.name.contains("\(viewModel.numberOfObjects - 1)") {
                viewModel.addShoulderTimerEntity()
            }
        }
    }
    
    // 충돌 종료를 감지하여 타이머를 중지
    func handleCollisionEnd(collisionEvent: CollisionEvents.Ended) {
        let entityName = collisionEvent.entityB.name
        
        if entityName.contains("Timer") {
            viewModel.timerController?.stop()
            viewModel.stopAllTimerProgress()
            isColliding = false
        }
    }
    
    // 충돌 상태가 5초 지속된 후 실행할 함수
    func executeCollisionAction() {
        // 충돌이 5초간 유지된 후 실행할 코드
        isColliding = false
        viewModel.resetHandEntities()
        viewModel.isFistShowing = false
        viewModel.isFirstPositioning = false
        
        if !viewModel.isRightDone {
            viewModel.isRightDone = true
            viewModel.addLeftHandAnchor()
        } else {
            viewModel.isRightDone = false
            viewModel.addRightHandAnchor()
        }
    }
}

#Preview {
    ShoulderStretchingView()
}
