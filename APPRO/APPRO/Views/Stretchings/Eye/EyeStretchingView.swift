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
                dump("viewModel.loadEntities failed: \(error)")
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
            LongPressGesture(minimumDuration: 1.0)
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
        .onChange( of: viewModel.currentDisturbObject, initial: false) {
            viewModel.handleCurrentDisturbEntityIndexChanged()
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
                switch phase {
                case .waiting:
                    try configureWaitingPhase(content: content)
                case .ready:
                    try await configureReadyPhase(content: content)
                case .start:
                    configureStartPhase(content: content)
                case .stretching:
                    configureStretchingPhase(content: content)
                case .finished:
                    configureFinishedPhase(content: content)
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
        
        try ringEntity.appear()
        try monitorEntity.playOpacityAnimation(from: 0.0, to: 1.0)
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        
        viewModel.handleEyeRingCollisionState()
        viewModel.disturbObjects.forEach { content.add($0.entity) }
        
        viewModel.stretchingPhase = .start
    }
    
    func configureStartPhase(content: RealityViewContent) {
        viewModel.setDisturbObjectsPosition()
        
        viewModel.disturbObjects.forEach { disturbObject in
            disturbObject.entity.components.set(OpacityComponent(opacity: 0.0))
        }
        
        viewModel.stretchingPhase = .stretching
    }
    
    func configureStretchingPhase(content: RealityViewContent) {
        guard viewModel.currentDisturbObject != nil else {
            viewModel.stretchingPhase = .finished
            return
        }
    }
    
    func configureFinishedPhase(content: RealityViewContent) {
        Task {
            do {
                try await Task.sleep(nanoseconds: 1 * 1000_000_000)
                
                await MainActor.run {
                    viewModel.disturbObjects.forEach {
                        $0.restoreScale()
                    }
                }
            } catch {
                dump("configureFinishedPhase failed: \(error)")
            }
        }
    }
    
}
