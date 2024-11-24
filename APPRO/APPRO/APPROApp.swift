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
    
    init() {
        LongPressGestureComponent.registerComponent()
        TapGestureComponent.registerComponent()
        ClosureComponent.registerComponent()
        ClosureSystem.registerSystem()
    }

    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup(id: appState.stretchingPartsWindowID) {
            StretchingPartsView()
                .environment(appState)
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
                    dismissWindow(id: appState.stretchingPartsWindowID)
                } else {
                    openWindow(id: appState.stretchingPartsWindowID)
                    await dismissImmersiveSpace()
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if (newPhase == .background || newPhase == .inactive) {
                appState.appPhase = .choosingStretchingPart
            }
        }

        ImmersiveSpace(id: appState.immersiveSpaceID) {
            if let stretchingPart = appState.currentStretchingPart, scenePhase == .active {
                if appState.appPhase == .tutorial && !TutorialManager.isSkipped(part: stretchingPart) {
                    tutorialImmersiveView(part: stretchingPart)
                        .preferredSurroundingsEffect(.semiDark)
                } else {
                    stretchingImmersiveView(part: stretchingPart)
                        .preferredSurroundingsEffect(appState.appPhase == .stretchingCompleted ? .ultraDark : .semiDark)
                }
            }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)

    }
    
    @ViewBuilder
    private func stretchingImmersiveView(part: StretchingPart) -> some View {
        switch part {
        case .eyes:
            EyeStretchingView()
                .environment(appState)
        case .shoulder:
            ShoulderStretchingView()
                .environment(appState)
        case .wrist:
            HandRollingStretchingView()
                .environment(appState)
        }
    }
    
    @ViewBuilder
    private func tutorialImmersiveView(part: StretchingPart) -> some View {
        switch part {
        case .eyes:
            EyeTutorialImmersiveView()
                .environment(appState)
        case .shoulder:
            ShoulderStretchingTutorialView()
                .environment(appState)
        case .wrist:
            HandRollingTutorialView()
                .environment(appState)
        }
    }
    
}
