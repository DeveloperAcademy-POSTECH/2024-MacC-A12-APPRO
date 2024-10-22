//
//  APPROApp.swift
//  APPRO
//
//  Created by 정상윤 on 10/8/24.
//

import SwiftUI

@main
struct APPROApp: App {

    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup(id: appState.stretchingPartsWindowID) {
            ContentView()
                .environment(appState)
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        
        WindowGroup(id: appState.stretchingPartsWindowID) {
            // TODO: 스트레칭 진행 윈도우 구현 및 추가
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        
        ImmersiveSpace(id: appState.immersiveSpaceID) {
            
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
