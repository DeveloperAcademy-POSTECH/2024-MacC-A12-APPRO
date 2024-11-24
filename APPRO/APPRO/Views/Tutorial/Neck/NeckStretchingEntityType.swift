//
//  NeckStretchingEntityType.swift
//  APPRO
//
//  Created by marty.academy on 11/21/24.
//

import Foundation

enum NeckStretchingEntityType: String {
    case pig
    case coin
    case timer
    
    var url : String {
        switch self {
        case .pig:
            "Neck/pig.usda"
        case .coin:
            "Neck/coin.usda"
        case .timer:
            "Neck/NeckTimer.usda"
        }
    }
}
