//
//  HandRollingImmersiveView.swift
//  APPRO
//
//  Created by marty.academy on 10/20/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

struct HandRollingStretchingView: View {
    @State var viewModel = HandRollingStretchingViewModel()
    @Environment(AppState.self) private var appState
    
    var body: some View {
        RealityView { content in
            await viewModel.makeFirstEntitySetting(content)
            viewModel.addEntity(content)
            viewModel.bringCollisionHandler(content)
            
        } update: { content in
            viewModel.addEntity(content)
            
            if viewModel.isRightHandInFist {
                viewModel.updateGuideComponentsTransform(content, chirality: .right)
            }
            
            if viewModel.isLeftHandInFist {
                viewModel.updateGuideComponentsTransform(content, chirality: .left)
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
                viewModel.rightEntities.append(viewModel.rightGuideRing)
                viewModel.rightEntities.append(viewModel.rightGuideSphere)
                Task {
                    try? await viewModel.playSpatialAudio(viewModel.rightGuideRing, audioInfo: AudioFindHelper.handGuideRingAppear)
                }
            } else {
                viewModel.rightGuideRing.removeFromParent()
                viewModel.rightGuideSphere.removeFromParent()
                viewModel.rightEntities.removeAll()
            }
        }
        .onChange(of: viewModel.isLeftHandInFist, initial: false) { _, isHandFistShape in
            if isHandFistShape {
                viewModel.leftEntities.append(viewModel.leftGuideRing)
                viewModel.leftEntities.append(viewModel.leftGuideSphere)
                Task {
                    try? await viewModel.playSpatialAudio(viewModel.rightGuideRing, audioInfo: AudioFindHelper.handGuideRingAppear)
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
                await viewModel.playRotationChangeRingSound(newValue)
            }
        }
        .onChange(of: viewModel.leftRotationCount, initial: false ) { _, newValue in
            let colorValueChangedTo = min (newValue * 2 + 1, 7)
            viewModel.getDifferentRingColor(viewModel.leftGuideRing, intChangeTo: Int32(colorValueChangedTo))
            Task {
                await viewModel.playRotationChangeRingSound(newValue)
            }
        }
        .onChange(of: viewModel.leftTargetEntities.count, initial: false ) { oldNumber, newNumber in
            if oldNumber > newNumber {
                viewModel.score += 1
            }
        }
        .onChange(of: viewModel.rightTargetEntities.count, initial: false ) { oldNumber, newNumber in
            if oldNumber > newNumber {
                viewModel.score += 1
            }
        }
        .onChange(of: viewModel.score, initial: false ) { _, changedScore  in
            appState.doneCount = changedScore
        }
        .onChange(of: viewModel.rightGuideSphere.scale.x, initial: false ) { oldScale, newScale in
            if newScale > oldScale {
                Task {
                    try? await viewModel.playSpatialAudio(viewModel.rightGuideRing, audioInfo: .handGuideSphereAppear)
                }
            }
        }
        .onChange(of: viewModel.leftGuideSphere.scale.x, initial: false ) { oldScale, newScale in
            if newScale > oldScale {
                Task {
                    try? await viewModel.playSpatialAudio(viewModel.leftGuideRing, audioInfo: .handGuideSphereAppear)
                }
            }
        }
    }
}
