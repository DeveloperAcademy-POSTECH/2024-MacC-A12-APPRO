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
    @State private var isAttachmentViewadjusted = false
    @State private var tutorialPreparations = Array(repeating: false, count: 5)
    
    
    var body : some View {
        RealityView { content, attachments in
            viewModel.addAttachmentView(content, attachments)
        } update: { content, _ in
            if areEntitiesAllLoaded {
                handleCurrentTutorialStep(content, currentStepIndex: tutorialManager.currentStepIndex)
                viewModel.addCoinEntity(content)
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
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { tapEvent in
                    
                    // Pig's the most exterior-close model entity name : ______
                    if tapEvent.entity.name == "______" {
                        if tutorialManager.currentStepIndex == 0 {
                            makeDoneFirstStep()
                            tutorialPreparations[0] = true
                        } else if viewModel.coinEntities.count == 0 {
                            viewModel.makeSemiCircleWithCoins()
                            if tutorialManager.currentStepIndex == 1 {
                                makeDoneSecondStep()
                            }
                        } else {
                            viewModel.resetCoins()
                        }
                    }
                }
        )
        .onChange(of: viewModel.coinEntities, initial: false) {}
        .onChange(of: viewModel.completionStatusArray) { _, completionStatusArray in
            if completionStatusArray.allSatisfy({ $0 == true}) {
                tutorialManager.advanceToNextStep()
            }
        }
    }
    
    private func handleCurrentTutorialStep(_ content: RealityViewContent, currentStepIndex: Int) {
        Task { @MainActor in
            if !tutorialPreparations[currentStepIndex] {
                switch currentStepIndex {
                case 0:
                    prepareFirstStep(content)
                case 1:
                    prepareSecondStep()
                case 2:
                    prepareThirdStep(content)
                case 3:
                    print(0)
                default :
                    return
                }
            }
        }
    }
    
    private func prepareFirstStep(_ content: RealityViewContent) {
        viewModel.configureInitialSettingToPig()
        viewModel.locatedPigOnFixedLocation()
        
        viewModel.adjustAttachmentViewLocation()
        content.add(viewModel.pigEntity)
    }
    
    private func makeDoneFirstStep () {
        viewModel.configureDeviceTrackingToPigEntity()
        tutorialManager.advanceToNextStep()
    }
    
    private func prepareSecondStep () {
        tutorialPreparations[1] = true
    }
    
    private func makeDoneSecondStep() {
        tutorialManager.advanceToNextStep()
    }
    
    private func prepareThirdStep(_ content: RealityViewContent) {
        viewModel.subscribePigCollisionEvent(content)
    }
}
