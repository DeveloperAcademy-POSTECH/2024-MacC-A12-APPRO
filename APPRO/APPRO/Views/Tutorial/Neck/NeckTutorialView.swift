//
//  NeckTutorialView.swift
//  APPRO
//
//  Created by marty.academy on 11/21/24.
//

import SwiftUI
import RealityKit

struct NeckTutorialView: View {
    
    @State private var viewModel = NeckStretchingViewModel()
    @State private var tutorialManager = TutorialManager(stretching: .neck)
    
    @State private var areEntitiesAllLoaded = false
    @State private var tutorialPreparations = Array(repeating: false, count: 5)
    
    var body : some View {
        RealityView { content, attachments in
            let warningEntity = createTextEntity("Stay aware of your surroundings")
            content.add(warningEntity)
            
            viewModel.addTutorialAttachmentView(attachments)
        } update: { content, _ in
            if areEntitiesAllLoaded {
                handleCurrentTutorialStep(content, currentStepIndex: tutorialManager.currentStepIndex)
                viewModel.addCoinEntity(content)
            }
        }
        attachments: {
            Attachment(id: viewModel.tutorialAttachmentViewID) {
                TutorialAttachmentView(tutorialManager: tutorialManager)
            }
        }
        .task {
            do {
                try await viewModel.loadEntities()
                areEntitiesAllLoaded = true
            } catch {
                areEntitiesAllLoaded = false
            }
        }
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { tapEvent in
                    
                    if tapEvent.entity.name == "pig" {
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
        guard let warningEntity = content.entities.first?.findEntity(named: "warning") else { return }
        withAnimation {
            warningEntity.isEnabled = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            Task {
                warningEntity.removeFromParent()
                viewModel.configureInitialSettingToPig()
                viewModel.locatedPigOnFixedLocation()
                
                viewModel.adjustAttachmentViewLocation(content)
                content.add(viewModel.pigEntity)
            }
        }
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
        tutorialPreparations[2] = true
    }
    
    func createTextEntity(_ text: String) -> ModelEntity {
        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: CGFloat(0.1)),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = ModelEntity(mesh: mesh, materials: [material])
        let width = textEntity.model?.mesh.bounds.extents.x ?? 0
        textEntity.name = "warning"
        textEntity.position = .init(x: -width/2, y: 1, z: -3)
        return textEntity
    }
}
