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
        .onChange(of: appState.appPhase.isImmersed) { _, isImmersed in
            Task {
                if isImmersed {
                    await openImmersiveSpace(id: appState.immersiveSpaceID)
                } else {
                    await dismissImmersiveSpace()
                }
            }
        }
        .onChange(of: appState.appPhase) { _, newPhase in
            handleAppPhase(newPhase)
        }
        
        WindowGroup(id: appState.stretchingProcessWindowID) {
            StretchingProcessView()
                .environment(appState)
                .onAppear {
                    dismissWindow(id: appState.stretchingPartsWindowID)
                    dismissWindow(id: appState.stretchingTutorialWindowID)
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
                .onChange(of: appState.tutorialManager?.isCompleted) { _, isCompleted in
                    appState.currentStretchingPart = appState.tutorialManager!.stretchingPart
                    appState.appPhase = .stretching
                }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultWindowPlacement { _, _ in
            return WindowPlacement(.utilityPanel)
        }
        
        ImmersiveSpace(id: appState.immersiveSpaceID) {
            switch appState.currentStretchingPart {
            case .eyes:
                EmptyView()
            case .shoulder:
                if let manager = appState.tutorialManager, manager.isSkipped {
                    ShoulderStretchingView()
                } else {
                    ShoulderStretchingTutorialView()
                }
            case .wrist:
                HandRollingStretchingView()
                    .environment(appState)
            default:
                EmptyView()
            }
        }
        .environment(appState)
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
    
    private func handleAppPhase(_ appPhase: AppPhase) {
        switch appPhase {
        case .choosingStretchingPart:
            openWindow(id: appState.stretchingPartsWindowID)
        case .stretching:
            openWindow(id: appState.stretchingProcessWindowID)
        case .tutorial:
            // TODO: 각 스트레칭 부위별 TutorialManager 분기
//            let tutorialManager = TutorialManager.sampleTutorialManager
            switch appState.currentStretchingPart {
            case .eyes:
                break
            case .shoulder:
                let shoulderTutorialManager = TutorialManager(stretching: .shoulder)
                appState.tutorialManager = shoulderTutorialManager
            case .wrist:
                break
            default:
                break
            }
//            if tutorialManager.isSkipped {
//                appState.appPhase = .stretching
//            } else {
//                appState.tutorialManager = tutorialManager
//                openWindow(id: appState.stretchingTutorialWindowID)
//            }
        }
    }
    
}
