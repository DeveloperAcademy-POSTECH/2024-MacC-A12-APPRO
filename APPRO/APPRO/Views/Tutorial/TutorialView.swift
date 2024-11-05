//
//  TutorialView.swift
//  APPRO
//
//  Created by 정상윤 on 10/31/24.
//

import SwiftUI

struct TutorialView: View {
    
    @Environment(AppState.self) var appState
    @Environment(\.scenePhase) var scenePhase
    @State private var showSkipAlert = false
    
    var body: some View {
        if let tutorialManager = appState.tutorialManager,
           !tutorialManager.isCompleted {
            VStack(alignment: .trailing, spacing: 16) {
                HStack {
                    Text("Tutorial")
                        .font(.extraLargeTitle2)
                    Spacer()
                    HStack(spacing: 16) {
                        // TODO: Mute 버튼 추가
                        Button("Skip Tutorial", systemImage: "forward.end") {
                            showSkipAlert = true
                        }
                        .labelStyle(.iconOnly)
                    }
                }
                Text(tutorialManager.currentStep.instruction)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 32, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                Spacer()
                Button("Next") {
                    tutorialManager.advanceToNextStep()
                }
                .font(.title3)
                .disabled(!tutorialManager.isNextEnabled)
            }
            .frame(width: 800, height: 300)
            .padding(32)
            .alert("Skip Tutorial", isPresented: $showSkipAlert) {
                Button("Yes") {
                    tutorialManager.skip()
                }
                Button("No", role: .cancel) {}
            } message: {
                Text("Start the content right away.\nNever show tutorial again.")
            }
            .glassBackgroundEffect()
            .onChange(of: scenePhase) { _, scenePhase in
                switch scenePhase {
                case .inactive, .background:
                    appState.appPhase = .choosingStretchingPart
                default:
                    break
                }
            }
        } else {
            Text("No Tutorial is Available")
        }
    }
    
}
    
#Preview(windowStyle: .plain) {
    let appState = AppState()
    appState.tutorialManager = TutorialManager.sampleTutorialManager
    return TutorialView()
        .environment(appState)
}
