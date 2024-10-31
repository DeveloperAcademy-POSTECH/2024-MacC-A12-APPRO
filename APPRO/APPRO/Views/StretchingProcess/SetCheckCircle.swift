//
//  SetCheckCircle.swift
//  APPRO
//
//  Created by 정상윤 on 10/24/24.
//

import SwiftUI

struct SetCheckCircle: View {
    
    let isChecked: Bool
    
    var body: some View {
        Circle()
            .frame(width: 66, height: 66)
            .foregroundStyle(.thickMaterial)
            .overlay {
                if isChecked {
                    Image(systemName: "checkmark")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .aspectRatio(contentMode: .fit)
                        .fontWeight(.light)
                }
            }
            .clipShape(.circle)
            .glassBackgroundEffect()
    }
    
}

#Preview(windowStyle: .plain) {
    SetCheckCircle(isChecked: true)
}
