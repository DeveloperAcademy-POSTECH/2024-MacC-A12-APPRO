//
//  ShoulderStretchingTutorialView.swift
//  APPRO
//
//  Created by Damin on 11/4/24.
//

import SwiftUI
import RealityKit


enum ShoulderTutorialStep: Int, CaseIterable {
    case step0
    case step1
    case step2
    case step3
}

struct ShoulderStretchingTutorialView: View {
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(AppState.self) var appState: AppState
    @State private var viewModel = ShoulderStretchingViewModel()
    @State private var isColliding: Bool = false
    @State private var currentStep: ShoulderTutorialStep = .step0
    @State private var realityContent: RealityViewContent?
    @State private var hasStarModelCreated: Bool = false
    
    var body: some View {
        RealityView { content in
            content.add(viewModel.contentEntity)
            let textEntity = createTextEntity("Stay aware of your surroundings")
            viewModel.contentEntity.addChild(textEntity)
            realityContent = content
            checkTutorialStep(content: content)

        } update: { content in
            switch currentStep {
            case .step0:
                break
            case .step1:
                // 팔의 위치를 감지해서 실행해야해서 update 클로저로 실행
                // TODO: minimumDistance 조정 필요
                viewModel.computEntryRocketForTutorial(minimumDistance: 0.4)
            case .step2, .step3:
                viewModel.computeTransformForTutorial()
            }
        }
        .onAppear() {
            dismissWindow(id: appState.stretchingPartsWindowID)
            appState.tutorialManager?.initializeSteps([
                .init(instruction: "엔트리 로켓 띄워지고 손뻗으라는 가이드", isCompleted: { false }),
                .init(instruction: "주먹을 쥐고 별을 생성할 수 있고 경로를 재설정 할 수 있다는 가이드", isCompleted: { false }),
                .init(instruction: "별을 순차적으로 터치해서 마지막에 타이머에서 5초 안내", isCompleted: { false })
            ])
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
        // TODO: next 버튼 감지, 일단 안내문으로 변화감지
        .onChange(of: appState.tutorialManager?.currentStep.instruction) { oldValue, newValue in
            // 이거 없으면 처음에 onChanage문이 실행되면서 step1으로 바로 넘어감
            if currentStep == .step0 { return }
            guard let step = ShoulderTutorialStep(rawValue: currentStep.rawValue + 1) else { return }
            currentStep = step
            guard let content = realityContent else { return }
            checkTutorialStep(content: content)
        }
        // step2에서 Star 모델이 생성이 됨을 감지 하기 위한 로직
        .onChange(of: viewModel.modelEntities) { oldValue, newValue in
            if currentStep == .step2 && !hasStarModelCreated && !newValue.isEmpty {
                hasStarModelCreated = true
                appState.tutorialManager?.isNextEnabled = true
            }
        }
    }
    
    // 각 단계에서 넘어갈때 한번만 실행 되는 메서드
    func checkTutorialStep(content: RealityViewContent) {
        switch currentStep {
            // 주변 주의 안내 문구
        case .step0:
            guard let textEntity = viewModel.contentEntity.findEntity(named: "warning") else { return }
            withAnimation {
                textEntity.isEnabled = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                Task {
                    textEntity.removeFromParent()
                    openWindow(id: appState.stretchingTutorialWindowID)
                    await viewModel.setEntryRocket()
                    viewModel.setHandRocketEntity()
                    subscribeToCollisionEvents(content: content)
                    currentStep = .step1
                }
            }
            
            // 엔트리 로켓 띄워지고 손뻗으라는 가이드 or 주먹을 쥐고 별을 생성할 수 있고 경로를 재설정 할 수 있다는 가이드
        case .step1, .step2:
            break

            // 별을 순차적으로 터치해서 마지막에 타이머에서 5초 안내
            // step3로 갔을때 별을 다시 생성
        case .step3:
            viewModel.reCreateRightStars()
        }
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
                // step1 next 버튼 활성화
                appState.tutorialManager?.isNextEnabled = true
            }else {
                animationEvent.playbackController.entity?.removeFromParent()
                
                //TODO: 튜토리얼 종료 로직 구현
                appState.tutorialManager?.isNextEnabled = true
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
            // step3일때만 마지막 엔터티를 충돌했을때 타이머가 추가되게 함
            if collidedModelEntity.name.contains("\(viewModel.numberOfObjects - 2)") && currentStep == .step3{
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
}

#Preview {
    ShoulderStretchingView()
}

