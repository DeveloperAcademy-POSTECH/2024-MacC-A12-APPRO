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

    @Environment(AppState.self) var appState: AppState
    
    var body: some View {
        VStack {
            Text(appState.appTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.title)
                .foregroundStyle(.white)
            
            Spacer()
            
            Model3D(
                named: appState.sharedSpaceObjectName,
                bundle: realityKitContentBundle
            ) { model in
                model
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 310, height: 310)
            
            Spacer()
            
            Button(action: {
                // TODO: Open Immersive Space
            }) {
                Text("Stretchy Out")
                    .frame(width: 161, height: 51)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
        .padding(24)
        .frame(width: 632, height: 554)
        .glassBackgroundEffect()
    }
    
}

#Preview(windowStyle: .plain) {
    ContentView()
        .environment(AppState())
}
