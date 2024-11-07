//
//  HandRollingTutorialView.swift
//  APPRO
//
//  Created by marty.academy on 11/7/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct HandRollingTutorialView : View {
    
    @State var viewModel = HandRollingTutorialViewModel()
    @State var tutorialManager = TutorialManager(stretching: .wrist)
    
    var body : some View {
        RealityView { content, attachments in
            if viewModel.isStartingObjectVisible {
                await viewModel.generateStartingObject(content)
            }
            
            await viewModel.makeFirstEntitySetting(content)
            viewModel.bringCollisionHandler(content)
            viewModel.addAttachmentView(content, attachments)
        } update : { content, attachments in
            viewModel.addEntity(content)
            
            if viewModel.isRightHandInFist {
                viewModel.updateGuideComponentsTransform(content, chirality: .right)
            }
            
            viewModel.addAttachmentView(content, attachments)
            
        } attachments: {
            Attachment(id: viewModel.tutorialAttachmentViewID) {
                TutorialAttachmentView(tutorialManager: tutorialManager)
            }
        }
        .task {
            await viewModel.start()
        }
        .task {
            await viewModel.publishHandTrackingUpdates()
        }
        .task {
            await viewModel.monitorSessionEvents()
        }
        .onChange(of: viewModel.isRightHandInFist, initial: false) { _, isHandFistShape in
            if !viewModel.isFistMakingTutorialDone {
                getNextTutorialStep(0)
                viewModel.isFistMakingTutorialDone = true
            }
            
            if isHandFistShape {
                if viewModel.isStartingObjectVisible { viewModel.isStartingObjectVisible = false}
                
                viewModel.rightEntities.append(viewModel.rightGuideRing)
                if tutorialManager.currentStepIndex > 1 {
                    viewModel.rightEntities.append(viewModel.rightGuideSphere)
                }
                
                Task {
                    try? await viewModel.playSpatialAudio(viewModel.rightGuideRing, audioInfo: AudioFindHelper.handGuideRingAppear)
                }
            } else {
                viewModel.rightGuideRing.removeFromParent()
                viewModel.rightGuideSphere.removeFromParent()
                viewModel.rightEntities.removeAll()
            }
        }
        .onChange(of: viewModel.isStartingObjectVisible, initial: false) {_, newValue in
            if !newValue {
                viewModel.getRidOfStartingObject()
            }
        }
        .onChange(of: tutorialManager.currentStepIndex, initial: false ) { _, currentStepIndex in
            getNextTutorialStep(1)
            getNextTutorialStep(2)
            getNextTutorialStep(5)
        }
        .onChange(of: viewModel.rightLaunchState, initial: false) { _, currentLaunchState in
            if currentLaunchState {
                Task {
                    viewModel.rightRotationForLaunchNumber = viewModel.rightRotationCount
                    try? await viewModel.rightEntities.append(viewModel.generateLaunchObj(chirality: .right))
                }
                
                DispatchQueue.main.async {
                    viewModel.rightLaunchState = false
                    viewModel.rightRotationCount = 0
                    getNextTutorialStep(4)
                }
            }
        }
        .onChange(of: viewModel.rightRotationCount, initial: false) { _, newValue in
            let colorValueChangedTo = min (newValue * 2, 6)
            viewModel.getDifferentRingColor(viewModel.rightGuideRing, intChangeTo: Int32(colorValueChangedTo))
            
            Task {
                await viewModel.playRotationChangeRingSound(newValue)
            }
            
            getNextTutorialStep(3)
        }
        .onChange(of: viewModel.rightHitCount, initial: false ) { oldNumber, newNumber in
            if oldNumber < newNumber {
                viewModel.doneCount += 1
            }
        }
        .onChange(of: viewModel.rightTargetEntity, initial: false ) {_, newOne in
            // 0...5 : step 의 인덱스들 -> 이 이중에서 과녁이 없어진다면, 4, 5 단계 빼고는 유저가 튜토리얼 하는 과정에서 과녁을 없앤다면 새롭게 나와야한다. 
            if newOne.name != "GreenTarget_right" && tutorialManager.currentStepIndex >= 2 && tutorialManager.currentStepIndex < 4 {
                Task {
                    await viewModel.rightTargetEntity = viewModel.bringTargetEntity(chirality: .right)
                }
            }
        }
    }
    
    private func getNextTutorialStep(_ currentStepIndex: Int) {
        if tutorialManager.currentStepIndex == currentStepIndex {
            if currentStepIndex == 2 {
                viewModel.showTarget = true
            }
            tutorialManager.completeCurrentStep()
        }
    }
}

#Preview {
    HandRollingTutorialView()
}
