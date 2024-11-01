//
//  APPROApp.swift
//  APPRO
//
//  Created by 정상윤 on 10/8/24.
//

import SwiftUI

@main
struct APPROApp: App {
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.scenePhase) private var scenePhase

    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup(id: appState.stretchingPartsWindowID) {
            StretchingPartsView()
                .environment(appState)
                .onAppear {
                    dismissWindow(id: appState.stretchingTutorialWindowID)
                    dismissWindow(id: appState.stretchingProcessWindowID)
                }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultWindowPlacement { _, context in
            guard let previousWindow = context.windows.first else { return WindowPlacement(.none) }
            
            return WindowPlacement(.above(previousWindow))
        }
        .onChange(of: appState.appPhase) { _, newPhase in
            Task {
                switch newPhase {
                case .choosingStretchingPart:
                    await configureStretchingPartsScene()
                case .stretching:
                    await configureStretchingScene()
                case .tutorial:
                    // TODO: 각 스트레칭 부위별 TutorialManager 분기
                    let tutorialManager = TutorialManager.sampleTutorialManager
                    
                    if tutorialManager.isSkipped {
                        appState.appPhase = .stretching
                    } else {
                        appState.tutorialManager = tutorialManager
                        await configureTutorialScene()
                    }
                }
            }
        }
        
        WindowGroup(id: appState.stretchingProcessWindowID) {
            StretchingProcessView()
                .environment(appState)
                .onAppear {
                    dismissWindow(id: appState.stretchingPartsWindowID)
                    dismissWindow(id: appState.stretchingProcessWindowID)
                }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultWindowPlacement { _, _ in
            return WindowPlacement(.utilityPanel)
        }
        
        WindowGroup(id: appState.stretchingTutorialWindowID) {
            TutorialView()
                .environment(appState)
                .onAppear {
                    dismissWindow(id: appState.stretchingPartsWindowID)
                }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultWindowPlacement { _, _ in
            return WindowPlacement(.utilityPanel)
        }
        
        ImmersiveSpace(id: appState.immersiveSpaceID) {
            // TODO: 각 스트레칭에 따른 뷰 추가
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
    
    private func configureStretchingPartsScene() async {
        openWindow(id: appState.stretchingPartsWindowID)
        await dismissImmersiveSpace()
    }
    
    private func configureStretchingScene() async {
        openWindow(id: appState.stretchingProcessWindowID)
        await openImmersiveSpace(id: appState.immersiveSpaceID)
    }
    
    private func configureTutorialScene() async {
        openWindow(id: appState.stretchingTutorialWindowID)
        await openImmersiveSpace(id: appState.immersiveSpaceID)
        
    }
    
}
