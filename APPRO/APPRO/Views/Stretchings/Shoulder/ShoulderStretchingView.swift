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

    var body: some View {
        RealityView { content in
            content.add(viewModel.contentEntity)
            subscribeToCollisionEvents(content: content)
        } update: { content in
            viewModel.computeTransformHandTracking()
        }
        .upperLimbVisibility(.hidden)
        .ignoresSafeArea()
        .onAppear() {
            viewModel.addRightHandAnchor()
        }
        .task {
            await viewModel.startHandTrackingSession()
        }
        .task {
            await viewModel.updateHandTracking()
        }
    }
    
    func subscribeToCollisionEvents(content: RealityViewContent) {
        // 충돌 시작 감지
        _ = content.subscribe(to: CollisionEvents.Began.self, on: viewModel.rightHandModelEntity.rocketEntity) { collisionEvent in
            setCollisionAction(collisionEvent: collisionEvent, isRight: true)
        }
        
        _ = content.subscribe(to: CollisionEvents.Began.self, on: viewModel.leftHandModelEntity.rocketEntity) { collisionEvent in
            setCollisionAction(collisionEvent: collisionEvent, isRight: false)
        }
        
        // 충돌 종료 감지
        _ = content.subscribe(to: CollisionEvents.Ended.self, on: viewModel.rightHandModelEntity.rocketEntity) { collisionEvent in
            handleCollisionEnd(collisionEvent: collisionEvent)
        }
        
        _ = content.subscribe(to: CollisionEvents.Ended.self, on: viewModel.leftHandModelEntity.rocketEntity) { collisionEvent in
            handleCollisionEnd(collisionEvent: collisionEvent)
        }
        
        // 애니메이션 종료 감지
        _ = content.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: nil) { animationEvent in
            animationEvent.playbackController.entity?.removeFromParent()
            executeCollisionAction()
        }
    }
    
    func setCollisionAction(collisionEvent: CollisionEvents.Began, isRight: Bool) {
        let entityName = isRight ? "rightModelEntity" : "leftModelEntity"
        let collidedModelEntity = collisionEvent.entityB
        // 충돌시 particle, audio 실행
        viewModel.playEmitter(eventEntity: collidedModelEntity)
        Task {
            await viewModel.playSpatialAudio(collidedModelEntity)
        }
        // 다음 엔터티 일때만 Material 변경
        if collidedModelEntity.name == "\(entityName)-\(viewModel.expectedNextNumber)" {
            viewModel.changeMatreialColor(entity: collidedModelEntity)
            viewModel.addExpectedNextNumber()
        }
        
        // 마지막 엔터티 감지
        if collidedModelEntity.name.contains("\(viewModel.numberOfObjects - 1)") {
            viewModel.resetExpectedNextNumber()
            // 충돌 상태가 유지되고 있는지 확인하기 위해 타이머를 설정
            if !viewModel.isColliding {
                viewModel.isColliding = true
                viewModel.addShoulderTimerEntity()
            }
        }
    }
    
    // 충돌 상태가 5초 지속된 후 실행할 함수
    func executeCollisionAction() {
        // 충돌이 5초간 유지된 후 실행할 코드
        viewModel.isColliding = false
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
    
    // 충돌 종료를 감지하여 타이머를 중지
    func handleCollisionEnd(collisionEvent: CollisionEvents.Ended) {
        let entityName = collisionEvent.entityB.name
        
        // 마지막 충돌 엔터티가 아닌 경우 또는 충돌이 끝났을 경우 타이머 중지
        if entityName.contains("\(viewModel.numberOfObjects - 1)") {
            viewModel.shoulderTimerEntity.removeFromParent()
            viewModel.isColliding = false
        }
    }
}

#Preview {
    ShoulderStretchingView()
}
