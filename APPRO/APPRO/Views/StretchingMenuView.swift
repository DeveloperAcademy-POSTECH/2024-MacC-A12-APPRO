//
//  StretchingMenuView.swift
//  APPRO
//
//  Created by 정상윤 on 10/8/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct StretchingMenuView: View {
    
    @Environment(AppState.self) private var appState
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 32),
        GridItem(.flexible(), spacing: 32)
    ]
        
    var body: some View {
        VStack {
            Text("Stretching Parts")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.extraLargeTitle)
            
            LazyVGrid(columns: columns, spacing: 32) {
                ForEach(Stretching.allCases) { type in
                    StretchingCard(stretching: type)
                }
            }
        }
    }
}

#Preview(windowStyle: .plain) {
    StretchingMenuView()
        .environment(AppState())
        .glassBackgroundEffect()
}
