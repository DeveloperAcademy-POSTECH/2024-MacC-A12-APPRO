//
//  NeckTutorialView.swift
//  APPRO
//
//  Created by marty.academy on 11/21/24.
//

import SwiftUI
import RealityKit

struct NeckTutorialView: View {
    
    @State private var viewModel = NeckTutorialViewModel()
    @State private var tutorialManager = TutorialManager(stretching: .neck)
    
    @State private var areEntitiesAllLoaded = false
    @State private var tutorialPreparations = Array(repeating: false, count: 5)
    
    var body : some View {
        RealityView { content, attachments in
            viewModel.addAttachmentView(content, attachments)
            // TODO: attachmentView 위치 조정하기. x, y, 고정하고 위치만 가변.
            
        } update: { content, _ in
            if areEntitiesAllLoaded {
                handleCurrentTutorialStep(content, currentStepIndex: tutorialManager.currentStepIndex)
            }
        }
        attachments: {
            Attachment(id: viewModel.attachmentViewID) {
                TutorialAttachmentView(tutorialManager: tutorialManager)
            }
        }
        .task {
            areEntitiesAllLoaded = await viewModel.loadEntities()
        }
        
        // TODO: onTabGesture에서 configureFirstStep -> Done
    }
    
    private func handleCurrentTutorialStep(_ content: RealityViewContent, currentStepIndex: Int) {
        Task { @MainActor in
            if !tutorialPreparations[currentStepIndex] {
                switch currentStepIndex {
                case 0:
                    prepareFirstStep(content)
                case 1:
                    print(0)
                case 2:
                    print(0)
                case 3:
                    print(0)
                default :
                    return
                }
            }
        }
    }
    
    private func prepareFirstStep(_ content: RealityViewContent) {
//        viewModel.configurePigEntity()
        viewModel.locatedPigOnFixedLocation()
        content.add(viewModel.pigEntity)
    }
}
