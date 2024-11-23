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
                do {
                    try configure(
                        content: content,
                        phase: viewModel.stretchingPhase
                    )
                } catch {
                    dump("EyeStretchingView configure failed: \(error)")
                }
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
    ) throws {
        switch phase {
        case .waiting:
            try configureWaitingPhase(content: content)
        case .started:
            break
        case .finished:
            break
        }
    }
    
    private func configureWaitingPhase(content: RealityViewContent) throws {
        try viewModel.configureEyesEntity()
        content.add(viewModel.eyesEntity)
    }
    
}
