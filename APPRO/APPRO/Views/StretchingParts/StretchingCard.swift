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
            .aspectRatio(1.67, contentMode: .fit)
            .background {
                // TODO: 스트레칭 부위별 배경 이미지 추가
                Color.teal
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .buttonBorderShape(.roundedRectangle)
    }
    
}

#Preview(windowStyle: .plain) {
    StretchingCard(stretching: .eyes)
        .frame(width: 300)
        .environment(AppState())
}
