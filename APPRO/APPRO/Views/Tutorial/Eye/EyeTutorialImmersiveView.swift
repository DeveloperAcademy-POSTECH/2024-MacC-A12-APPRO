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
    @State private var configureCompleted = Array(repeating: false, count: 4)
    
    var body: some View {
        RealityView { content, attachments in
            tutorialManager.addAttachmentView(content: content, attachments: attachments)
            tutorialManager.configureAttachmentView(entity: tutorialManager.attachmentView)
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
        .task {
            entitiesAllLoaded = await tutorialManager.loadEntities()
        }
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    if value.entity.name == "patch" {
                        tutorialManager.step1()
                    }
                }
        )
        .gesture(
            LongPressGesture(minimumDuration: 2.0)
                .targetedToEntity(tutorialManager.chickenEntity)
                .updating($isLongPressing) { currentValue, gestureState, _ in
                    gestureState = currentValue.gestureValue
                }
                .onEnded { _ in
                    tutorialManager.handleLongPressOnEnded()
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
                    tutorialManager.step2()
                case 2:
                    configureStep2(content: content)
                default:
                    break
                }
                configureCompleted[currentStepIndex] = true
            }
        }
    }
    
    private func configureStep1(content: RealityViewContent) {
        let eyesEntity = tutorialManager.eyesEntity
        
        tutorialManager.configureEyesEntity(entity: eyesEntity)
        
        content.add(eyesEntity)
    }
    
    private func configureStep2(content: RealityViewContent) {
        let chickenEntity = tutorialManager.chickenEntity
        
        tutorialManager.configureChickenEntity(entity: chickenEntity)
        tutorialManager.playAppearAnimation(entity: chickenEntity)
        
        content.add(chickenEntity)
    }
    
}
