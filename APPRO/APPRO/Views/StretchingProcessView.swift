//
//  StretchingProcessView.swift
//  APPRO
//
//  Created by 정상윤 on 10/15/24.
//

import SwiftUI

struct StretchingProcessView: View {
    
    let stretching: Stretching
    
    @State private var animateIn = true
    
    var body: some View {
        EmptyView()
            .opacity(animateIn ? 0.0 : 1.0)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                    withAnimation(.easeInOut(duration: 0.7)) {
                        animateIn = false
                    }
                }
            }
            .onDisappear {
                animateIn = true
            }
    }
    
}

#Preview {
    StretchingProcessView(stretching: .eyes)
}
