//
//  ShoulderStretchingView.swift
//  APPRO
//
//  Created by Damin on 10/30/24.
//

import SwiftUI
import RealityKit

struct ShoulderStretchingView: View {
    @State private var viewModel = ShoulderStretchingViewModel()

    var body: some View {
        RealityView { content in
            content.add(viewModel.contentEntity)
            //TODO: 충돌 이벤트 구독 액션 호출
        } update: { content in
            viewModel.computeTransformHandTracking()
        }
        .upperLimbVisibility(.hidden)
        .ignoresSafeArea()
        .onAppear() {
            viewModel.setupRocketEntity()
            viewModel.addRightHandAnchor()
        }
        .task {
            await viewModel.startHandTrackingSession()
        }
        .task {
            await viewModel.updateHandTracking()
        }
    }
}

#Preview {
    ShoulderStretchingView()
}
