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
    @State private var configureCompleted: [EyeStretchingPhase: Bool] = [
        .waiting: false,
        .ready: false,
        .started: false,
        .finished: false
    ]
    @GestureState private var isLongPressing = false
    
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
        .gesture(
            LongPressGesture(minimumDuration: 2.0)
                .targetedToEntity(where: .has(LongPressGestureComponent.self))
                .updating($isLongPressing) { currentValue, gestureState, _ in
                    gestureState = currentValue.gestureValue
                }
                .onEnded { value in
                    guard let longPressGesture = value.entity.components[LongPressGestureComponent.self] else {
                        dump("No LongPressGestureComponent found")
                        return
                    }
                    longPressGesture.onEnded()
                }
        )
        .onChange(of: isLongPressing) { _, isLongPressing in
            viewModel.handleLongPressingUpdate(value: isLongPressing)
        }
        .onChange(of: viewModel.currentDisturbEntity) { prevEntity, currentEntity in
            do {
                prevEntity?.disappear()
                try currentEntity?.playOpacityAnimation(from: 0.0, to: 1.0)
            } catch {
                dump("onChange(of: viewModel.currentDisturbEntity failed: \(error)")
            }
        }
    }
    
}

private extension EyeStretchingView {
    
    func configure(
        content: RealityViewContent,
        phase: EyeStretchingPhase
    ) {
        Task {
            do {
                if configureCompleted[phase] == false {
                    switch phase {
                    case .waiting:
                        try configureWaitingPhase(content: content)
                        configureCompleted[phase] = true
                    case .ready:
                        try await configureReadyPhase(content: content)
                        configureCompleted[phase] = true
                    case .started:
                        try configureStartedPhase(content: content)
                    case .finished:
                        break
                    }
                }
            } catch {
                dump("configure failed: \(error)")
            }
        }
    }
    
    func configureWaitingPhase(content: RealityViewContent) throws {
        try viewModel.configureEyesEntity()
        content.add(viewModel.eyesEntity)
    }
    
    func configureReadyPhase(content: RealityViewContent) async throws {
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
        
        viewModel.handleEyeRingCollisionState()
        viewModel.setDisturbEntitiesPosition()
        
        viewModel.stretchingPhase = .started
    }
    
    func configureStartedPhase(content: RealityViewContent) throws {
        guard let currentDisturbEntity = viewModel.currentDisturbEntity else {
            viewModel.stretchingPhase = .finished
            return
        }
        
        content.add(currentDisturbEntity)
    }
    
}
