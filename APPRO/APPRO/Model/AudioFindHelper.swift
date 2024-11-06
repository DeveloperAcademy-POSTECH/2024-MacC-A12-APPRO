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
    case handStartAppear
    case handSprialAppear
    case handGuideSphereAppear
    case handGuideRingAppear
    case handRotationOnce
    case handRotationTwice
    case handRotationThreeTimes
    case handTargetAppear(chirality: Chirality)
    case handTargetHitRight(chirality: Chirality)
    case handTargetHitWrong(chirality: Chirality)
}

extension AudioFindHelper {
    var detail: AudioInfo {
        switch self {
        case .handStartAppear: return AudioInfo(spatialAudioName: "FloatingSpatialAudio", resourceLocation: "/root/hand_starting_wav", resourceFrom: "Hand/main_obj_applied.usd")
        case .handSprialAppear: return AudioInfo(spatialAudioName: "AppearSpatialAudio", resourceLocation: "/root/spiral_launch_wav", resourceFrom: "Hand/spiral_new.usd")
        case .handGuideRingAppear: return AudioInfo(spatialAudioName: "AppearSpatialAudio", resourceLocation: "/root/ring_appear_wav", resourceFrom: "Hand/wrist_ring.usd")
        case .handGuideSphereAppear: return AudioInfo(spatialAudioName: "AppearSpatialAudio", resourceLocation: "/root/guide_sphere_appear_wav", resourceFrom: "Hand/wrist_ring.usd")
        case .handRotationOnce: return AudioInfo(spatialAudioName: "RotationSpatialAudio", resourceLocation: "/root/_1_rotation_wav", resourceFrom: "Hand/wrist_ring.usd")
        case .handRotationTwice: return AudioInfo(spatialAudioName: "RotationSpatialAudio", resourceLocation: "/root/_2_rotation_wav", resourceFrom: "Hand/wrist_ring.usd")
        case .handRotationThreeTimes : return AudioInfo(spatialAudioName: "RotationSpatialAudio", resourceLocation: "/root/_3_rotation_wav", resourceFrom: "Hand/wrist_ring.usd")
        case .handTargetAppear(let chirality): return AudioInfo(spatialAudioName: "AppearSpatialAudio", resourceLocation: "/root/target_appear_mp3", resourceFrom: "Hand/target_new_\(getBlueOrGreen(chirality)).usd")
        case .handTargetHitRight(let chirality): return AudioInfo(spatialAudioName: "AppearSpatialAudio", resourceLocation: "/root/target_right_hit_wav", resourceFrom: "Hand/target_new_\(getBlueOrGreen(chirality)).usd")
        case .handTargetHitWrong(let chirality): return AudioInfo(spatialAudioName: "AppearSpatialAudio", resourceLocation: "/root/target_error_wav", resourceFrom: "Hand/target_new_\(getBlueOrGreen(chirality)).usd")
        }
    }
    
    private func getBlueOrGreen(_ chirality: Chirality) -> String {
        if chirality == .left {
            return "blue"
        } else {
            return "green"
        }
    }
}



