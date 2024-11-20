//
//  TutorialAttachmentView.swift
//  APPRO
//
//  Created by 정상윤 on 10/31/24.
//

import SwiftUI

struct TutorialAttachmentView: View {
    
    @State private var showSkipAlert = false
    @Bindable var tutorialManager: TutorialManager
    @Environment(AppState.self) var appState: AppState
    
    var body: some View {
        if let currentStep = tutorialManager.currentStep {
            ZStack {
                VStack(alignment: .trailing, spacing: 16) {
                    HStack {
                        HStack(spacing: 16) {
                            Button("Dismiss Immersive Space", systemImage: "multiply") {
                                appState.appPhase = .choosingStretchingPart
                                appState.currentStretchingPart = nil
                            }
                            .labelStyle(.iconOnly)
                        }
                        Text("Tutorial")
                            .font(.extraLargeTitle2)
                        Spacer()
                        HStack(spacing: 16) {
                            Button("Skip Tutorial", systemImage: "forward.end") {
                                presentSkipAlert(true)
                            }
                            .labelStyle(.iconOnly)
                        }
                    }
                    Text(currentStep.instruction)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 32, weight: .medium))
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                        .onAppear {
                            tutorialManager.playInstructionAudio()
                        }
                        .onChange(of: tutorialManager.currentStepIndex, initial: false) { _, _ in
                            tutorialManager.playInstructionAudio()
                        }
                    
                    Spacer()
                    
                    if tutorialManager.isLastStep {
                        Button("Done") {
                            tutorialManager.skip()
                            tutorialManager.stopInstructionAudio()
                            appState.appPhase = .stretching
                        }
                        .font(.title3)
                    }
                }
                .frame(width: 800, height: 300)
                .padding(32)
                .opacity(showSkipAlert ? 0.3 : 1.0)
                .blur(radius: showSkipAlert ? 1.5 : 0.0)
                
                skipTutorialAlertView
                    .opacity(showSkipAlert ? 1.0 : 0.0)
                
            }
            .glassBackgroundEffect()
        }
    }
    
    private func presentSkipAlert(_ show: Bool) {
        withAnimation(.easeInOut(duration: 0.5)) {
            showSkipAlert = show
        }
    }
    
    private var skipTutorialAlertView: some View {
        VStack(spacing: 15) {
            VStack(spacing: 5) {
                Text("Skip Tutorial")
                    .font(.title2)
                Text("Start the content right away.\nNever show tutorial again.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
            }
            Divider()
            Button("Yes") {
                tutorialManager.skip()
                tutorialManager.stopInstructionAudio()
                appState.appPhase = .stretching
            }
            .frame(maxWidth: .infinity, maxHeight: 44)
            .buttonStyle(.borderless)
            Button("No", role: .cancel) {
                presentSkipAlert(false)
            }
            .frame(maxWidth: .infinity, maxHeight: 44)
            .buttonStyle(.borderless)
        }
        .frame(width: 320, height: 240)
        .padding(20)
        .glassBackgroundEffect()
    }
    
}

#Preview(windowStyle: .plain) {
    TutorialAttachmentView(tutorialManager: .init(stretching: .eyes))
}
