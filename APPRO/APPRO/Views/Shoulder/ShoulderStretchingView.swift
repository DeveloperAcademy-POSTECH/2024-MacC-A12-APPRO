//
//  ImmersiveView.swift
//  ParabolaTest
//
//  Created by Damin on 10/11/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ShoulderStretchingView: View {
    
    @State private var viewModel = ShoulderStretchingViewModel()
    @State private var subscription: EventSubscription?
    
    var body: some View {
        RealityView { content in
            
            content.add(viewModel.contentEntity)
            
            subscription = content.subscribe(to: CollisionEvents.Began.self, on: viewModel.rightMiddleFingerKnuckleModelEntity) { collisionEvent in
                //                print("🫲 Collision between \(collisionEvent.entityA.name) and \(collisionEvent.entityB.name)")
                
                if collisionEvent.entityB.name.contains("animationEntity") {
                    guard let animationEntity = viewModel.contentEntity.findEntity(named: collisionEvent.entityB.name) else {
                        debugPrint("not found animationEntity")
                        return
                    }
                    
                    viewModel.playEmitter(eventEntity: animationEntity)
                    
                    Task {
                        do {
                            try await viewModel.playSpatialAudio(animationEntity)
                        } catch {
                            debugPrint("playSpatialAudio error: \(error)")
                        }
                    }
                }
            }
        } update: { content in
            viewModel.computeTransformHandTracking()
        }
        .upperLimbVisibility(.hidden)
        .ignoresSafeArea()
        .onAppear {
            viewModel.addHandAnchor()
        }
        .task {
            await viewModel.handTracking_2()
        }
    }
}
