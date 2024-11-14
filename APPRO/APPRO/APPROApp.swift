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
                    await dismissImmersiveSpace()
                }
            }
        }
        .onChange(of: appState.appPhase) { _, newPhase in
            if newPhase == .choosingStretchingPart {
                openWindow(id: appState.stretchingPartsWindowID)
            }
        }
        
        ImmersiveSpace(id: appState.immersiveSpaceID) {
            if let stretchingPart = appState.currentStretchingPart {
                if appState.appPhase == .tutorial && !TutorialManager.isSkipped(part: stretchingPart) {
                    tutorialImmersiveView(part: stretchingPart)
                } else {
                    stretchingImmersiveView(part: stretchingPart)
                }
            }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
    
    @ViewBuilder
    private func stretchingImmersiveView(part: StretchingPart) -> some View {
        switch part {
        case .eyes:
            EmptyView()
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
            // TODO: 눈 튜토리얼 몰입 뷰 추가
            EmptyView()
        case .shoulder:
            ShoulderStretchingTutorialView()
                .environment(appState)
        case .wrist:
            HandRollingTutorialView()
                .environment(appState)
        }
    }
    
}
