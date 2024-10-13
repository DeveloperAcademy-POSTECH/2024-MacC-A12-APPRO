//
//  Stretching.swift
//  APPRO
//
//  Created by 정상윤 on 10/13/24.
//

enum Stretching: String, Identifiable, CaseIterable {
    
    case eyes, wrist, neck, shoulder
    
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
        case .neck:
            "Restore neck fatigue by stretching your head left and right up and down"
        case .shoulder:
            "Restore shoulder fatigue by stretching your shoulders left and right, up and down"
        }
    }
    
    var requiredTime: Int {
        switch self {
        case .eyes: 5
        case .wrist: 5
        case .neck: 5
        case .shoulder: 5
        }
    }
    
}
