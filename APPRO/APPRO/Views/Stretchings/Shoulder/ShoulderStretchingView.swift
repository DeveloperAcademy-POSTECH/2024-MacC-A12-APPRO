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
        RealityView { content in
            content.add(viewModel.contentEntity)
            await viewModel.setEntryRocket()
            viewModel.setHandRocketEntity()
            subscribeToCollisionEvents(content: content)
        } update: { content in
            viewModel.computeTransformHandTracking()
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
            }
        }
    }
    
    func setCollisionAction(collisionEvent: CollisionEvents.Began) {
        
        let collidedModelEntity = collisionEvent.entityB
        
        if collidedModelEntity.name.contains("Timer") && !isColliding {
            viewModel.playAnimation(animationEntity: viewModel.shoulderTimerEntity)
            isColliding = true
            return
        }
        
        let entityName = viewModel.isRightDone ? "leftModelEntity" : "rightModelEntity"
        
        // 충돌시 particle, audio 실행
        viewModel.playEmitter(eventEntity: collidedModelEntity)
        Task {
            await viewModel.playSpatialAudio(collidedModelEntity)
        }
        // 다음 엔터티 일때만 Material 변경
        if collidedModelEntity.name == "\(entityName)-\(viewModel.expectedNextNumber)" {
            viewModel.changeMatreialColor(entity: collidedModelEntity)
            viewModel.addExpectedNextNumber()
            
            // 마지막 엔터티 감지
            if collidedModelEntity.name.contains("\(viewModel.numberOfObjects - 2)") {
                viewModel.addShoulderTimerEntity()
                
            }
        }
    }
    
    // 충돌 종료를 감지하여 타이머를 중지
    func handleCollisionEnd(collisionEvent: CollisionEvents.Ended) {
        let entityName = collisionEvent.entityB.name
        if entityName.contains("Timer") {
            viewModel.timerController?.stop()
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
