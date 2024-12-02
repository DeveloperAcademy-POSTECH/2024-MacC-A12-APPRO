//
//  SpatialAudioHelper.swift
//  APPRO
//
//  Created by Damin on 11/27/24.
//

import Foundation
import RealityKit

protocol AudioEffect: Hashable {
    static var allCases: [Self] { get }
    var fileName: String { get }
}

extension AudioEffect where Self: RawRepresentable, Self.RawValue == String {
    var fileName: String { rawValue }
}

// SoundHelper 클래스 정의
final class SoundEffectHelper<T: AudioEffect> {
    private var loadedSounds: [T: AudioFileResource] = [:]
    private let queue = DispatchQueue(label: "SoundEffectHelper")
    private var isLoaded = false

    init() {
        Task {
            await loadSounds()
            queue.sync {
                isLoaded = true
            }
        }
    }
    
    private func loadSounds() async {
        do {
            try await withThrowingTaskGroup(of: (T, AudioFileResource).self) { group in
                for effect in T.allCases {
                    group.addTask {
                        //TODO: wav 확장자만 가능한것 추후 수정
                        let resource = try await AudioFileResource(named: "\(effect.fileName).wav")
                        return (effect, resource)
                    }
                }
                for try await (effect, resource) in group {
                    queue.sync {
                        self.loadedSounds[effect] = resource
                    }
                }
            }
        } catch {
            debugPrint("Failed to load one or more sounds: \(error)")
        }
    }
    
    func playSound(_ effect: T, on entity: Entity, isSpatial: Bool = true) {
        queue.sync {
            if !isLoaded {
                debugPrint("Sounds are still loading. Please wait...")
                return
            }
        }
        // 이후 동기적으로 실행
        queue.sync { [weak self] in
            guard let resource = self?.loadedSounds[effect] else {
                debugPrint("Sound not loaded: \(effect.fileName)")
                return
            }
            
            if isSpatial {
                entity.components.set(SpatialAudioComponent())
            }
            
            let audioController = entity.prepareAudio(resource)
            audioController.play()
        }
    }
}

// 부위별 SoundEffect Enum 정의
enum ShoulderSoundEffects: String, AudioEffect, CaseIterable {
    case star1, star2, star3, star4, star5, star6
    case entryRocket
    case shoulderTimer
    
    static var stars: [ShoulderSoundEffects] {
        allCases.filter { $0.rawValue.starts(with: "star") }
    }
}

enum WristSoundEffects: String, AudioEffect, CaseIterable {
    case handStartAppear
    case handSprialAppear
    case handGuideRingAppear
    case handRotationOnce, handRotationTwice, handRotationThreeTimes
    case handTargetHitRight, handTargetHitWrong
}

// TODO: 눈 예시
enum EyeSoundEffects: String, AudioEffect, CaseIterable {
    case focusGain, distractionCut, eyeStretch
}
enum NeckSoundEffects: String, AudioEffect, CaseIterable {
    case rightCoinHit
    case wrongCoinHit
    case neckTimer
}
