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
            //TODO: 충돌 이벤트 구독 액션 호출
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
                viewModel.toggleIsColliding()
                viewModel.addShoulderTimerEntity()
            }
        }
    }
    
    // 충돌 상태가 5초 지속된 후 실행할 함수
    func executeCollisionAction() {
        // 충돌이 5초간 유지된 후 실행할 코드
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
