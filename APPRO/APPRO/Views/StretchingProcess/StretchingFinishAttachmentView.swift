//
//  StretchingAttachmentView.swift
//  APPRO
//
//  Created by 정상윤 on 10/24/24.
//

import SwiftUI
import RealityKit

struct StretchingFinishAttachmentView: View {
    
    @Environment(AppState.self) private var appState
    
    let counter: StretchingCounter
    let stretchingPart: StretchingPart
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .center) {
                Text("Result")
                    .font(.largeTitle)
                Text("\(stretchingPart.title) Stretch")
                    .font(.title)
            }
            
            if stretchingPart == .eyes || stretchingPart == .wrist {
                Text("\(counter.doneCount) / \(counter.maxCount)")
                    .font(.system(size: 60))
                    .fontWeight(.semibold)
            } else {
                HStack(spacing: 15) {
                    ForEach(0..<counter.maxCount, id: \.self) { idx in
                        SetCheckCircle(isChecked: counter.doneCount >= idx + 1)
                    }
                }
            }
            
            Divider()
            
            VStack {
                Button {
                    counter.makeDoneCountZero()
                }label: {
                    Text("Retry")
                }
                
                Button {
                    appState.appPhase = .choosingStretchingPart
                }label: {
                    Text("Finish")
                }
            }
            
        }
        .frame(width: 550)
        .padding(24)
        .padding(.bottom, 24)
        .glassBackgroundEffect()
    }
}


#Preview {
    StretchingFinishAttachmentView(counter: ShoulderStretchingViewModel(), stretchingPart: .wrist)
}
