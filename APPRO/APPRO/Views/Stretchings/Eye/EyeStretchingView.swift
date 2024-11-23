//
//  EyeStretchingView.swift
//  APPRO
//
//  Created by 정상윤 on 11/20/24.
//

import SwiftUI
import RealityKit

struct EyeStretchingView: View {
    
    @State private var viewModel = EyeStretchingViewModel()
    @State private var allEntitiesLoaded = false
    
    var body: some View {
        RealityView { content, attachments in
            do {
                try viewModel.addAttachmentView(
                    content: content,
                    attachments: attachments
                )
                viewModel.configureAttachmentView()
            } catch {
                dump("RealityView make failed: \(error)")
            }
        } update: { content, attachments in
            if allEntitiesLoaded {
                configure(
                    content: content,
                    phase: viewModel.stretchingPhase
                )
            }
        } attachments: {
            Attachment(id: viewModel.attachmentViewID) {
                StretchingAttachmentView(
                    counter: viewModel,
                    stretchingPart: .eyes
                )
            }
        }
        .task {
            do {
                try await viewModel.loadEntities()
                allEntitiesLoaded = true
            } catch {
                allEntitiesLoaded = false
            }
        }
        .gesture(
            TapGesture()
                .targetedToEntity(where: .has(TapGestureComponent.self))
                .onEnded { value in
                    guard let component = value.entity.components[TapGestureComponent.self] else {
                        dump("TapGestureComponent not found!")
                        return
                    }
                    component.onEnded()
                }
        )
    }
    
    private func configure(
        content: RealityViewContent,
        phase: EyeStretchingPhase
    ) {
        Task {
            do {
                switch phase {
                case .waiting:
                    try configureWaitingPhase(content: content)
                case .ready:
                    try await configureReadyPhase(content: content)
                case .started:
                    configureStartedPhase(content: content)
                    break
                case .finished:
                    break
                }
            } catch {
                dump("EyeStretchingView configure failed: \(error)")
            }
        }
    }
         
    private func configureWaitingPhase(content: RealityViewContent) throws {
        try viewModel.configureEyesEntity()
        content.add(viewModel.eyesEntity)
    }
    
    private func configureReadyPhase(content: RealityViewContent) async throws {
        let ringEntity = viewModel.ringEntity
        let eyesEntity = viewModel.eyesEntity
        let monitorEntity = viewModel.monitorEntity
        
        content.add(ringEntity)
        content.add(monitorEntity)
        
        try await eyesEntity.setCollisionComponent()
        try await viewModel.configureRingEntity()
        viewModel.configureMonitorEntity()
        
        try ringEntity.playOpacityAnimation(from: 0.0, to: 1.0)
        try monitorEntity.playOpacityAnimation(from: 0.0, to: 1.0)
        
        viewModel.stretchingPhase = .started
    }
    
    private func configureStartedPhase(content: RealityViewContent) {
        let disturbEntities = viewModel.disturbEntities
        
        viewModel.configureDisturbEntities()
        
        disturbEntities.forEach { content.add($0) }
    }
    
}
