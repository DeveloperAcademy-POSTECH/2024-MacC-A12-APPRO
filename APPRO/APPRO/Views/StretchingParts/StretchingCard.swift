//
//  StretchingCard.swift
//  APPRO
//
//  Created by 정상윤 on 10/22/24.
//

import SwiftUI

struct StretchingCard: View {
    
    @Environment(AppState.self) private var appState
    
    let stretching: Stretching
    
    var body: some View {
        Button(action: {
            appState.appPhase = .isStretching(stretching)
        }) {
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 10) {
                    Text(stretching.title)
                        .font(.title3)
                    
                    Text(stretching.description)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .foregroundStyle(.white)
                .background(.thinMaterial)
            }
            .background {
                Image(stretching.backgroundImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .frame(width: 498, height: 280)
        .buttonStyle(.plain)
        .buttonBorderShape(.roundedRectangle)
    }
    
}

#Preview(windowStyle: .plain) {
    StretchingCard(stretching: .eyes)
        .frame(width: 300)
        .environment(AppState())
}
