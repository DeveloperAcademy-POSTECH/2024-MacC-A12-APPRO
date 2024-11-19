//
//  HandRollingImmersiveView.swift
//  APPRO
//
//  Created by marty.academy on 10/20/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct HandRollingStretchingView: View {
    @State var viewModel = HandRollingStretchingViewModel()
    
    var body: some View {
        RealityView { content, attachments in
            if viewModel.isStartingObjectVisible {
                await viewModel.generateStartingObject(content)
            }
            await viewModel.makeFirstEntitySetting()
            viewModel.addEntity(content)
            viewModel.bringCollisionHandler(content)
            viewModel.subscribeSceneEvent(content)
            viewModel.addAttachmentView(content, attachments)
            
        } update: { content, attachments in
            
            if viewModel.maxCount == viewModel.doneCount {
                viewModel.showFinishAttachmentView(content, attachments)
            } else {
                if viewModel.isRetry {
                    viewModel.deleteEndAttachmentView(content, attachments)
                    viewModel.isRetry = false
                }
                
                viewModel.addEntity(content)
                
                if viewModel.isStartingObjectVisible {
                    viewModel.updateStartingComponentsTransform(content)
                } else if !viewModel.areTargetTranslationUpdated {
                    viewModel.updateTargetsComponentTransform(content)
                }
                
                if viewModel.isRightHandInFist {
                    viewModel.updateGuideComponentsTransform(content, chirality: .right)
                }
                
                if viewModel.isLeftHandInFist {
                    viewModel.updateGuideComponentsTransform(content, chirality: .left)
                }
                
                viewModel.addAttachmentView(content, attachments)
            }
        } attachments: {
            Attachment(id: viewModel.stretchingAttachmentViewID) {
                StretchingAttachmentView(counter: viewModel, stretchingPart: .wrist)
            }
            
            Attachment(id: viewModel.stretchingFinishAttachmentViewID) {
                StretchingFinishAttachmentView(counter: viewModel, stretchingPart: .wrist)
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
        .onChange(of: viewModel.rightLaunchState, initial: false) { _, currentLaunchState in
            if currentLaunchState {
                Task {
                    viewModel.rightRotationForLaunchNumber = viewModel.rightRotationCount
                    try? await viewModel.rightEntities.append(viewModel.generateLaunchObj(chirality: .right))
                }
                
                DispatchQueue.main.async {
                    viewModel.rightLaunchState = false
                    viewModel.rightRotationCount = 0
                }
            }
        }
        .onChange(of: viewModel.leftLaunchState, initial: false) { _, currentLaunchState in
            if currentLaunchState {
                Task {
                    viewModel.leftRotationForLaunchNumber = viewModel.leftRotationCount
                    try? await viewModel.leftEntities.append(viewModel.generateLaunchObj(chirality: .left))
                }
                
                DispatchQueue.main.async {
                    viewModel.leftLaunchState = false
                    viewModel.leftRotationCount = 0
                }
            }
        }
        .onChange(of: viewModel.isRightHandInFist, initial: false) { _, isHandFistShape in
            if isHandFistShape {
                if viewModel.isStartingObjectVisible { viewModel.isStartingObjectVisible = false}
                
                viewModel.rightEntities.append(viewModel.rightGuideRing)
                viewModel.rightEntities.append(viewModel.rightGuideSphere)
                Task {
                    await viewModel.playSpatialAudio(viewModel.rightGuideRing, audioInfo: AudioFindHelper.handGuideRingAppear)
                }
            } else {
                viewModel.rightGuideRing.removeFromParent()
                viewModel.rightGuideSphere.removeFromParent()
                viewModel.rightEntities.removeAll()
            }
        }
        .onChange(of: viewModel.isLeftHandInFist, initial: false) { _, isHandFistShape in
            if isHandFistShape {
                if viewModel.isStartingObjectVisible { viewModel.isStartingObjectVisible = false}
                
                viewModel.leftEntities.append(viewModel.leftGuideRing)
                viewModel.leftEntities.append(viewModel.leftGuideSphere)
                Task {
                    await viewModel.playSpatialAudio(viewModel.leftGuideRing, audioInfo: AudioFindHelper.handGuideRingAppear)
                }
            } else {
                viewModel.leftGuideRing.removeFromParent()
                viewModel.leftGuideSphere.removeFromParent()
                viewModel.leftEntities.removeAll()
            }
        }
        .onChange(of: viewModel.rightRotationCount, initial: false) { _, newValue in
            let colorValueChangedTo = min (newValue * 2, 6)
            viewModel.getDifferentRingColor(viewModel.rightGuideRing, intChangeTo: Int32(colorValueChangedTo))
            Task {
                await viewModel.playRotationChangeRingSound(newValue, chirality: .right)
            }
        }
        .onChange(of: viewModel.leftRotationCount, initial: false ) { _, newValue in
            let colorValueChangedTo = min (newValue * 2 + 1, 7)
            viewModel.getDifferentRingColor(viewModel.leftGuideRing, intChangeTo: Int32(colorValueChangedTo))
            Task {
                await viewModel.playRotationChangeRingSound(newValue, chirality: .left)
            }
        }
        .onChange(of: viewModel.rightHitCount, initial: false ) { oldNumber, newNumber in
            if oldNumber < newNumber {
                dump(viewModel.doneCount)
                viewModel.doneCount += 1
            }
        }
        .onChange(of: viewModel.leftHitCount, initial: false ) { oldNumber, newNumber in
            if oldNumber < newNumber {
                dump(viewModel.doneCount)
                viewModel.doneCount += 1
            }
        }
        .onChange(of: viewModel.isStartingObjectVisible, initial: false) {_, newValue in
            if !newValue {
                viewModel.getRidOfStartingObject()
            }
        }
        .onChange(of: viewModel.startObject, initial: false) { _, newValue in
            if newValue.name == "StartingObject" {
                Task {
                    await viewModel.playSpatialAudio(newValue, audioInfo: .handStartAppear)
                }
            }
        }
        .onChange(of: viewModel.doneCount, initial: false) { oldValue, newValue in
            if oldValue > newValue && newValue == 0 {
                Task {
                    await viewModel.makeFirstEntitySetting(isRetry: true)
                    viewModel.isRetry = true
                }
            }
        }
    }
}
