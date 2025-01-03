//
//  EyeTutorialImmersiveView.swift
//  APPRO
//
//  Created by 정상윤 on 11/7/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct EyeTutorialImmersiveView: View {
    
    @GestureState private var isLongPressing = false
    @State private var tutorialManager = EyeTutorialManager()
    @State private var entitiesAllLoaded = false
    @State private var configureCompleted = Array(repeating: false, count: 5)
    
    var body: some View {
        RealityView { content, attachments in
            tutorialManager.addAttachmentView(content: content, attachments: attachments)
            tutorialManager.configureAttachmentView()
        }
        update: { content, _ in
            if entitiesAllLoaded {
                handleCurrentStepIndex(
                    content: content,
                    currentStepIndex: tutorialManager.currentStepIndex
                )
            }
        }
        attachments: {
            Attachment(id: tutorialManager.attachmentViewID) {
                TutorialAttachmentView(tutorialManager: tutorialManager)
            }
        }
        .onDisappear {
            tutorialManager.resetAttactmentViewEntity()
        }
        .task {
            entitiesAllLoaded = await tutorialManager.loadEntities()
        }
        .gesture(
            TapGesture()
                .targetedToEntity(where: .has(TapGestureComponent.self))
                .onEnded { value in
                    guard let tapGestureComponent = value.entity.components[TapGestureComponent.self] else {
                        dump("No TapGestureComponent found")
                        return
                    }
                    tapGestureComponent.onEnded()
                }
        )
        .gesture(
            LongPressGesture(minimumDuration: 1.0)
                .targetedToEntity(where: .has(LongPressGestureComponent.self))
                .updating($isLongPressing) { currentValue, gestureState, _ in
                    gestureState = currentValue.gestureValue
                }
                .onEnded { value in
                    guard let longPressGesture = value.entity.components[LongPressGestureComponent.self] else {
                        dump("No LongPressGestureComponent found")
                        return
                    }
                    longPressGesture.onEnded()
                }
        )
        .onChange(of: isLongPressing) {
            tutorialManager.handleLongPressingUpdate(value: isLongPressing)
        }
    }
    
    private func handleCurrentStepIndex(
        content: RealityViewContent,
        currentStepIndex: Int
    ) {
        if !configureCompleted[currentStepIndex] {
            Task { @MainActor in
                switch currentStepIndex {
                case 0:
                    configureStep1(content: content)
                case 1:
                    configureStep2()
                case 2:
                    configureStep3(content: content)
                case 3:
                    await configureStep4(content: content)
                default:
                    return
                }
                configureCompleted[currentStepIndex] = true
            }
        }
    }
    
    private func configureStep1(content: RealityViewContent) {
        do {
            try tutorialManager.configureEyesEntity()
            content.add(tutorialManager.eyesObject.entity)
        } catch {
            dump("configureStep1 failed: \(error)")
        }
    }
    
    private func configureStep2() {
        tutorialManager.attachmentView.components.remove(ClosureComponent.self)
        tutorialManager.advanceToNextStep()
    }
    
    private func configureStep3(content: RealityViewContent) {
        do {
            let chickenObject = tutorialManager.chickenObject
            content.add(chickenObject.entity)
            try tutorialManager.configureChickenEntity()
            chickenObject.appear()
        } catch {
            dump("configureStep3 failed: \(error)")
        }
    }
    
    private func configureStep4(content: RealityViewContent) async {
        do {
            let eyesObject = tutorialManager.eyesObject
            let ringObject = tutorialManager.ringObject
            let monitorEntity = tutorialManager.monitorEntity
            
            tutorialManager.chickenObject.entity.removeFromParent()
            content.add(ringObject.entity)
            content.add(monitorEntity)
            
            try ringObject.appear()
            try monitorEntity.playOpacityAnimation(from: 0.0, to: 1.0)
            
            try await tutorialManager.configureRingEntity()
            try await eyesObject.setCollisionComponent()
            
            tutorialManager.configureMonitorEntity()
            try ringObject.subscribeCollisionEvent()
            
            tutorialManager.advanceToNextStep()
        } catch {
            dump("configureStep4 failed: \(error)")
        }
    }
    
}
