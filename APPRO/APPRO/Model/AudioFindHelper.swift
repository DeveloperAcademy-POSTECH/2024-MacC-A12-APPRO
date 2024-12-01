//
//  AudioFindHelper.swift
//  APPRO
//
//  Created by marty.academy on 11/5/24.
//
import SwiftUI

struct AudioInfo {
    var spatialAudioName: String
    var resourceLocation: String
    var resourceFrom: String
}

enum AudioFindHelper {
    case coinCollisionInRightOrder
    case coinCollisionInWrongOrder
}

extension AudioFindHelper {
    var detail: AudioInfo {
        switch self {
        case .coinCollisionInRightOrder: return AudioInfo(spatialAudioName: "CollisionSpatialAudio", resourceLocation: "/root/neck_sound_coin1_wav", resourceFrom: "Neck/coin.usda")
        case .coinCollisionInWrongOrder: return AudioInfo(spatialAudioName: "CollisionSpatialAudio", resourceLocation: "/root/neck_sound_error1_wav", resourceFrom: "Neck/coin.usda")
        }
    }
}



