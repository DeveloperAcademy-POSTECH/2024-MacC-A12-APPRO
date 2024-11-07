//
//  StretchingAttachmentView.swift
//  APPRO
//
//  Created by 정상윤 on 10/24/24.
//

import SwiftUI
import RealityKit

struct StretchingAttachmentView: View {
    
    @Environment(AppState.self) private var appState
    
    let counter: StretchingCounter
    let stretchingPart: StretchingPart
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack(alignment: .center) {
                HStack {
                    Button("Dismiss Immersive Space", systemImage: "multiply") {
                        appState.appPhase = .choosingStretchingPart
                    }
                    .labelStyle(.iconOnly)
                    
                    Spacer()
                }
                Text("\(stretchingPart.title) Stretch")
                    .font(.largeTitle)
            }
            
            if stretchingPart == .eyes || stretchingPart == .wrist {
                Text("Score")
                    .font(.title)
                    .opacity(0.96)
                Text("\(counter.doneCount) / \(counter.maxCount)")
                    .font(.system(size: 60))
                    .fontWeight(.semibold)
            } else {
                Text("Sets")
                    .font(.title)
                    .opacity(0.96)
                HStack(spacing: 15) {
                    ForEach(0..<counter.maxCount, id: \.self) { idx in
                        SetCheckCircle(isChecked: counter.doneCount == idx + 1)
                    }
                }
            }
            
            Button {
                UserDefaults.standard.setValue(false, forKey: "\(stretchingPart)TutorialSkipped")
            } label: {
                Text("Reset the Tutorial's User Default Value")
            }
        }
        .frame(width: 550)
        .padding(24)
        .padding(.bottom, 24)
        .glassBackgroundEffect()
    }
    
}
