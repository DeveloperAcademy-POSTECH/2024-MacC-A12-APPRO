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
            } else {
                viewModel.leftGuideRing.removeFromParent()
                viewModel.leftGuideSphere.removeFromParent()
                viewModel.leftEntities.removeAll()
            }
        }.onAppear {
            print("Immersive View is on the stage")
        }
    }
}
