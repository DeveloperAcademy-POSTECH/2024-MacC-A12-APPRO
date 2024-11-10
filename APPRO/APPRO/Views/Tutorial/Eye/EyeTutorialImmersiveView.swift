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
        .onChange(of: tutorialManager.currentStepIndex) { _, index in
            switch index {
            case 1:
                tutorialManager.step2()
            default:
                break
            }
        }
    }
    
}
