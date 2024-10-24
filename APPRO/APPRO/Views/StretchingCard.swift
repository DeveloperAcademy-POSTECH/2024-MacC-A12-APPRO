//
//  StretchingCard.swift
//  APPRO
//
//  Created by 정상윤 on 10/13/24.
//

import SwiftUI

struct StretchingCard: View {
    
    let stretching: Stretching
    
    var body: some View {
        NavigationLink(value: stretching) {
            VStack {
                Spacer()
                VStack(alignment: .leading) {
                    HStack(spacing: 5) {
                        Text(stretching.title)
                            .font(.title2)
                        Spacer()
                        HStack {
                            Image(systemName: "clock")
                            Text("\(stretching.requiredTime) min")
                            Image(systemName: "checkmark.circle")
                            Text("4 times") // TODO: 스트레칭 카운트 기능 구현
                        }
                        .font(.caption2)
                    }
                    Text(stretching.description)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.body)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(.white)
                .background(.thinMaterial)
            }
            .frame(maxWidth: .infinity)
        }
        .aspectRatio(1.67, contentMode: .fit)
        .background {
            Image("SampleImage")
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
}

#Preview(windowStyle: .plain) {
    StretchingCard(stretching: .shoulder)
        .frame(width: 350)
}
