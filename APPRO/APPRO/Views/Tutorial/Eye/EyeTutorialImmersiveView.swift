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
    
    @State private var tutorialManager = EyeTutorialManager()
    
    var body: some View {
        RealityView { content, attachments in
            await tutorialManager.addEyeAndPatchEntity(content: content)
            tutorialManager.addAttachmentView(content: content, attachments: attachments)
        } update: { content, _ in
            handleCurrentStepIndex(content: content)
        } attachments: {
            Attachment(id: tutorialManager.attachmentViewID) {
                TutorialAttachmentView(tutorialManager: tutorialManager)
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    tutorialManager.handleTapGestureValue(value)
                }
        )
        .onChange(of: tutorialManager.currentStepIndex) { _, _ in }
    }
    
    private func handleCurrentStepIndex(content: RealityViewContent) {
        Task { @MainActor in
            switch tutorialManager.currentStepIndex {
            case 1:
                tutorialManager.step2()
            case 2:
                await tutorialManager.addChickenEntity(content: content)
            default:
                break
            }
        }
    }
    
}
