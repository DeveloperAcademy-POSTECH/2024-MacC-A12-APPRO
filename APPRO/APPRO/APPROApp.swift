//
//  APPROApp.swift
//  APPRO
//
//  Created by 정상윤 on 10/8/24.
//

import SwiftUI

@main
struct APPROApp: App {
    
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup(id: "APPRO") {
            ContentView()
                .environment(appState)
                .onChange(of: appState.phase.isImmersed) { _, showImmersiveView in
                    if showImmersiveView {
                        Task {
                            await openImmersiveSpace(id: appState.immersiveSpaceID)
                        }
                    } else {
                        Task {
                            await dismissImmersiveSpace()
                        }
                    }
                }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        
        ImmersiveSpace(id: appState.immersiveSpaceID) {
            switch appState.currentStretchingPart {
            case .shoulder:
                ShoulderStretchingView()
                    .preferredSurroundingsEffect(.ultraDark)
            case .wrist:
                HandRollingImmersiveView()
                    .preferredSurroundingsEffect(.ultraDark)
            case .eyes:
                EyeStretchingView()
                    .preferredSurroundingsEffect(.ultraDark)
            default:
                EmptyView()
            }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
