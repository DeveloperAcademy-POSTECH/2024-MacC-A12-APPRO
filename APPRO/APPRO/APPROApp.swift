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

    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup(id: appState.stretchingPartsWindowID) {
            StretchingPartsView()
                .environment(appState)
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .onChange(of: appState.appPhase) { _, newPhase in
            switch newPhase {
            case .choosingStretchingPart:
                configureChoosingStretchingPartScene()
            case .isStretching(_):
                configureStretchingScene()
            }
        }
        
        WindowGroup(id: appState.stretchingProcessWindowID) {
            // TODO: 스트레칭 진행 윈도우 구현 및 추가
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        
        ImmersiveSpace(id: appState.immersiveSpaceID) {
            // TODO: 각 스트레칭에 따른 뷰 추가
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
    
    private func configureChoosingStretchingPartScene() {
        dismissWindow(id: appState.stretchingProcessWindowID)
        Task {
            await dismissImmersiveSpace()
        }
        openWindow(id: appState.stretchingPartsWindowID)
    }
    
    private func configureStretchingScene() {
        dismissWindow(id: appState.stretchingPartsWindowID)
        Task {
            await openImmersiveSpace(id: appState.immersiveSpaceID)
        }
        openWindow(id: appState.stretchingProcessWindowID)
    }
    
}
