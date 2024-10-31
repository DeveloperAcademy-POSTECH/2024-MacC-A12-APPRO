//
//  StretchingProcessView.swift
//  APPRO
//
//  Created by 정상윤 on 10/24/24.
//

import SwiftUI
import RealityKit

struct StretchingProcessView: View {
    
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        if let stretching = appState.currentStretching {
            VStack(spacing: 20) {
                ZStack(alignment: .center) {
                    HStack {
                        Button("Dismiss Immersive Space", systemImage: "multiply") {
                            appState.appPhase = .choosingStretchingPart
                        }
                        .labelStyle(.iconOnly)
                        
                        Spacer()
                    }
                    Text("\(stretching.title) Stretch")
                        .font(.largeTitle)
                }
                
                if stretching == .eyes || stretching == .wrist {
                    Text("Score")
                        .font(.title)
                        .opacity(0.96)
                    Text("\(appState.doneCount) / \(appState.maxCount)")
                        .font(.system(size: 60))
                        .fontWeight(.semibold)
                } else {
                    Text("Sets")
                        .font(.title)
                        .opacity(0.96)
                    HStack(spacing: 15) {
                        ForEach(0..<appState.maxCount, id: \.self) { idx in
                            SetCheckCircle(isChecked: appState.doneCount == idx + 1)
                        }
                    }
                }
            }
            .frame(width: 550)
            .padding(24)
            .padding(.bottom, 24)
            .glassBackgroundEffect()
            .onAppear {
                appState.resetStretchingCount()
                appState.doneCount = 1
            }
            .onChange(of: scenePhase) { _, scenePhase in
                switch scenePhase {
                case .inactive, .background:
                    appState.appPhase = .choosingStretchingPart
                default:
                    break
                }
            }
        }
    }
    
}

#Preview(windowStyle: .plain) {
    let appState = AppState()
    
    appState.appPhase = .isStretching(.shoulder)
    
    return StretchingProcessView()
        .environment(appState)
}
