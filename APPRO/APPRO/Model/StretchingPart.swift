//
//  Stretching.swift
//  APPRO
//
//  Created by 정상윤 on 10/13/24.
//

enum StretchingPart: String, Identifiable, CaseIterable {
    
    case eyes, wrist, shoulder
    
    var id: Self { self }
    
    var title: String {
        rawValue.capitalized
    }
    
    var description: String {
        switch self {
        case .eyes:
            "Restore eye fatigue through stretching that rolls both eyes"
        case .wrist:
            "Restore wrist fatigue through stretching that fixes arms and turns wrists"
        case .shoulder:
            "Restore shoulder fatigue by stretching your shoulders left and right, up and down"
        }
    }
    
    var maxCount: Int {
        switch self {
        case .eyes:
            12
        case .wrist:
            6
        case .shoulder:
            3
        }
    }
    
    var backgroundImageName: String {
        "\(self)_background"
    }
    
}
