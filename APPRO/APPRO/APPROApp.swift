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
        .defaultWindowPlacement { content, context in
            guard let stretchingProcessWindow = context.windows.first(where: { $0.id == appState.stretchingProcessWindowID }) else { return .init(.none) }
            
            return .init(.leading(stretchingProcessWindow))
        }
        .onChange(of: appState.appPhase) { _, newPhase in
            switch newPhase {
            case .choosingStretchingPart:
                configureChoosingStretchingPartScene()
            case .isStretching(_):
                configureStretchingScene()
            }
        }
        
        WindowGroup(id: appState.stretchingProcessWindowID) {
            if appState.currentStretching != nil {
                StretchingProcessView()
                    .environment(appState)
            }
        }
        .windowStyle(.plain)
        .defaultWindowPlacement { _, context in
            guard let stretchingPartsWindow = context.windows.first(where: { $0.id == appState.stretchingPartsWindowID }) else { return .init(.none) }
            
            return .init(.trailing(stretchingPartsWindow))
        }
        .windowResizability(.contentSize)
        
        ImmersiveSpace(id: appState.immersiveSpaceID) {
            // TODO: 각 스트레칭에 따른 뷰 추가
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
    
    private func configureChoosingStretchingPartScene() {
        Task {
            openWindow(id: appState.stretchingPartsWindowID)
            dismissWindow(id: appState.stretchingProcessWindowID)
            await dismissImmersiveSpace()
        }
    }
    
    private func configureStretchingScene() {
        Task {
            openWindow(id: appState.stretchingProcessWindowID)
            await openImmersiveSpace(id: appState.immersiveSpaceID)
            dismissWindow(id: appState.stretchingPartsWindowID)
        }
    }
    
}
