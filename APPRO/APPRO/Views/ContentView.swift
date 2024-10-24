//
//  ContentView.swift
//  APPRO
//
//  Created by 정상윤 on 10/8/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    
    @Environment(AppState.self) private var appState: AppState
    @Environment(\.scenePhase) private var scenePhase: ScenePhase
    
    @State private var isReducedFrame = false
    
    var body: some View {
        @Bindable var appState = appState
        
        NavigationStack {
            StretchingMenuView()
                .onAppear {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                        return
                    }
                    
                    windowScene.requestGeometryUpdate(.Vision(resizingRestrictions: UIWindowScene.ResizingRestrictions.none))
                }
                .navigationDestination(for: Stretching.self) { stretching in
                    StretchingProcessView(stretching: stretching)
                        .transition(.opacity)
                        .navigationTitle(stretching.title)
                        .onAppear {
                            animate()
                            appState.currentStretchingPart = stretching
                            appState.phase = .isStretching
                        }
                        .onDisappear {
                            animate()
                            appState.phase = .choosingStretchingPart
                            appState.currentStretchingPart = nil
                        }
                }
        }
        .frame(
            width: isReducedFrame ? 300 : 900,
            height: isReducedFrame ? 150 : 720
        )
        .padding()
        .glassBackgroundEffect()
    }
    
    private func animate() {
        Task {
            try? await Task.sleep(for: .seconds(0.1))
            withAnimation(.easeIn(duration: 1.0)) {
                isReducedFrame.toggle()
            }
        }
    }
    
}

#Preview(windowStyle: .plain) {
    ContentView()
        .environment(AppState())
}
