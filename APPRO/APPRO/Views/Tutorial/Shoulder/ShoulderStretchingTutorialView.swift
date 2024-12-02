//
//  ShoulderStretchingTutorialView.swift
//  APPRO
//
//  Created by Damin on 11/4/24.
//

import SwiftUI
import RealityKit

struct ShoulderStretchingTutorialView: View {
    
    @State private var tutorialManager = TutorialManager(stretching: .shoulder)
    @State private var viewModel = ShoulderStretchingTutorialViewModel()
    @State private var isColliding: Bool = false
    @State var isStartWarningDone = false
    
    var body: some View {
        RealityView { content, attachments in
            content.add(viewModel.contentEntity)
            let textEntity = createTextEntity(String(localized: "Stay aware of your surroundings"))
            viewModel.contentEntity.addChild(textEntity)
            setTutorialToStart(content, attachments)
        } update: { content, attachments in
            if !tutorialManager.isLastStep {
                viewModel.computeTransformHandTracking(currentStep: tutorialManager.currentStepIndex)
            }
        } attachments: {
            Attachment(id: viewModel.tutorialAttachmentViewID) {
                TutorialAttachmentView(tutorialManager: tutorialManager)
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
        .onChange(of: tutorialManager.currentStepIndex, initial: false) { _, newValue in
            switch tutorialManager.currentStepIndex {
            case 1:
                tutorialManager.advanceToNextStep()
            case 4:
                viewModel.resetModelEntities()
                viewModel.createEntitiesOnEllipticalArc(handTransform: viewModel.rightHandTransform)
            default:
                break
            }
        }
        .onChange(of: viewModel.modelEntities) { _, newValue in
            if let _ = newValue.first(where: {$0.name.contains("star")}) {
                if tutorialManager.currentStepIndex == 2 {
                    tutorialManager.advanceToNextStep()
                }
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
                tutorialManager.advanceToNextStep()
            } else {
                // 타이머 애니메이션 종료시
                animationEvent.playbackController.entity?.removeFromParent()
                tutorialManager.advanceToNextStep()
                executeCollisionAction()
            }
        }
    }
    
    func setCollisionAction(collisionEvent: CollisionEvents.Began) {
        // 팔뻗는 인스트럭션 전에는 무효화
        if tutorialManager.currentStepIndex < 3 {
            return
        }
        let collidedModelEntity = collisionEvent.entityB
        
        if collidedModelEntity.name.contains("TimerCollisionModel") && !isColliding {
            viewModel.playCustomAnimation(timerEntity: viewModel.shoulderTimerEntity)
            viewModel.initiateAllTimerProgress()
            isColliding = true
            return
        }
        
        let entityNumber = Int(collidedModelEntity.name.dropFirst(4)) ?? 0
        
        // 순서가 아닌 엔터티 일때 에미터, 소리 나오지 않도록 조건 수정
        if entityNumber <= viewModel.expectedNextNumber {
            viewModel.playEmitter(eventEntity: collidedModelEntity)
            
            if let effect = ShoulderSoundEffects.allCases.first(where: { effect in
                guard let effectNumber = Int(effect.rawValue.dropFirst(4)) else { return false }
                // 나머지를 이용해 숫자를 대응
                return (entityNumber - 1) % ShoulderSoundEffects.stars.count + 1 == effectNumber
            }) {
                viewModel.soundHelper.playSound(effect, on: collidedModelEntity)
            } else {
                viewModel.soundHelper.playSound(.star1, on: collidedModelEntity)
            }
            
            // 다음 엔터티 일때만 Material 변경
            if collidedModelEntity.name == "star\(viewModel.expectedNextNumber)" {
                viewModel.changeMatreialColor(entity: collidedModelEntity)
                viewModel.addExpectedNextNumber()
                
                // 마지막 엔터티 감지
                if collidedModelEntity.name.contains("\(viewModel.numberOfObjects - 1)") {
                    if tutorialManager.currentStepIndex == 3 {
                        tutorialManager.advanceToNextStep()
                    }
                    
                    if tutorialManager.currentStepIndex >= 4  {
                        viewModel.addShoulderTimerEntity()
                    }
                }
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
        viewModel.resetModelEntities()
        viewModel.resetExpectedNextNumber()
    }
    
    func createTextEntity(_ text: String) -> ModelEntity {
        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: CGFloat(0.1)),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = ModelEntity(mesh: mesh, materials: [material])
        let width = textEntity.model?.mesh.bounds.extents.x ?? 0
        textEntity.name = "warning"
        textEntity.position = .init(x: -width/2, y: 1, z: -3)
        return textEntity
    }
    
    func setTutorialToStart(_ content: RealityViewContent, _ attachments: RealityViewAttachments) {
        if tutorialManager.currentStepIndex == 0 {
            guard let textEntity = viewModel.contentEntity.findEntity(named: "warning") else { return }
            withAnimation {
                textEntity.isEnabled = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                Task {
                    textEntity.removeFromParent()
                    await viewModel.setEntryRocket()
                    viewModel.setHandRocketEntity()
                    subscribeToCollisionEvents(content: content)
                    isStartWarningDone = true
                    viewModel.addAttachmentView(content, attachments)
                }
            }
        }
    }
}
