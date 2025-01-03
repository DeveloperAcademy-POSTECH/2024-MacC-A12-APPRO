//
//  StretchingPartsView.swift
//  APPRO
//
//  Created by 정상윤 on 10/8/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct StretchingPartsView: View {
    
    @Environment(AppState.self) var appState: AppState
    
    private let spacing: CGFloat = 30.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text("Stretching Parts")
                .font(.largeTitle)
            
            Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
                GridRow {
                    StretchingCard(stretching: .eyes)
                    StretchingCard(stretching: .wrist)
                }
                GridRow {
                    StretchingCard(stretching: .shoulder)
                    StretchingCard(stretching: .neck)
                }
            }
        }
        .padding(spacing)
        .glassBackgroundEffect()
    }
    
}

#Preview(windowStyle: .plain) {
    StretchingPartsView()
        .environment(AppState())
}
