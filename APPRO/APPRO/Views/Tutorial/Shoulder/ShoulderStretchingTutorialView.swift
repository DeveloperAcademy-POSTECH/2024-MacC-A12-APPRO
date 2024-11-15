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
            let textEntity = createTextEntity("Stay aware of your surroundings")
            viewModel.contentEntity.addChild(textEntity)
            setTutorialToStart(content: content)
            
        } update: { content, attachments in
            
            switch tutorialManager.currentStepIndex {
            case 0:
                if isStartWarningDone {
                    viewModel.computeTransformHandTracking(currentStep: tutorialManager.currentStepIndex)
                    viewModel.addAttachmentView(content,attachments)
                } else {
                    viewModel.computeTransformHandTracking(currentStep: tutorialManager.currentStepIndex)
                }
            default:
                completeTutorialStep(1)
                completeTutorialStep(5) // The last step in the tutorial
                
                viewModel.computeTransformHandTracking(currentStep: tutorialManager.currentStepIndex)
                viewModel.addAttachmentView(content,attachments)
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
            if newValue == 4 {
                viewModel.addShoulderTimerEntity()
            }
        }
        .onChange(of: viewModel.modelEntities) { _, newValue in
            if let _ = newValue.first(where: {$0.name.contains("rightModelEntity")}) {
                completeTutorialStep(2)
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
                completeTutorialStep(0) // Tutorial Step 0 Completed
            } else {
                animationEvent.playbackController.entity?.removeFromParent()
                completeTutorialStep(4)
                executeCollisionAction()
            }
        }
    }
    
    func setCollisionAction(collisionEvent: CollisionEvents.Began) {
        let collidedModelEntity = collisionEvent.entityB
        
        if collidedModelEntity.name.contains("Timer") && !isColliding {
            viewModel.playAnimation(animationEntity: viewModel.shoulderTimerEntity)
            viewModel.initiateAllTimerProgress()
            viewModel.playCustomAnimation(timerEntity: viewModel.shoulderTimerEntity)
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
                completeTutorialStep(3)
                
                if tutorialManager.currentStepIndex >= 4  {
                    viewModel.addShoulderTimerEntity()
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
        viewModel.isFistShowing = false
        viewModel.isFirstPositioning = false
        viewModel.addRightHandAnchor()
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
    
    private func completeTutorialStep(_ currentStepIndex: Int) {
        if tutorialManager.currentStepIndex == currentStepIndex {
            tutorialManager.completeCurrentStep()
        }
    }
    
    func setTutorialToStart(content: RealityViewContent) {
        if tutorialManager.currentStepIndex == 0 {
            guard let textEntity = viewModel.contentEntity.findEntity(named: "warning") else { return }
            withAnimation {
                textEntity.isEnabled = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                Task {
                    textEntity.removeFromParent()
                    await viewModel.setEntryRocket()
                    viewModel.setHandRocketEntity()
                    subscribeToCollisionEvents(content: content)
                    viewModel.subscribeSceneEvent(content)
                    isStartWarningDone = true
                }
            }
        }
    }
}