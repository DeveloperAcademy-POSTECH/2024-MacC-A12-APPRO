//
//  SpatialAudioHelper.swift
//  APPRO
//
//  Created by Damin on 11/27/24.
//

import Foundation
import RealityKit

protocol SoundEffectProtocol: Hashable {
    static var allCases: [Self] { get }
    var fileName: String { get }
    func playSound(on entity: Entity, resource: AudioFileResource)
}

extension SoundEffectProtocol where Self: RawRepresentable, Self.RawValue == String {
    var fileName: String { rawValue }
    
    func playSound(on entity: Entity, resource: AudioFileResource) {
        /// SpatailAudioComponent 적용
        entity.components.set(SpatialAudioComponent())
        let audioController = entity.prepareAudio(resource)
        audioController.play()
    }
}

// SoundHelper 클래스 정의
final class SoundEffectHelper<T: SoundEffectProtocol> {
    private var loadedSounds: [T: AudioFileResource] = [:]
    private let queue = DispatchQueue(label: "SoundEffectHelper")

    init() {
        Task {
            await loadSounds()
        }
    }
    
    private func loadSounds() async {
        for effect in T.allCases {
            do {
                let resource = try await AudioFileResource(named: "\(effect.fileName).wav")
                queue.sync { [weak self] in
                    self?.loadedSounds[effect] = resource
                }
            } catch {
                debugPrint("Failed to load sound: \(effect.fileName), \(error)")
            }
        }
    }
    
    func playSound(_ effect: T, on entity: Entity, offset: Duration? = nil) {
        queue.sync { [weak self] in
            guard let resource = self?.loadedSounds[effect] else {
                debugPrint("Sound not loaded: \(effect.fileName)")
                return
            }
            effect.playSound(on: entity, resource: resource)
        }
    }
}

// 부위별 SoundEffect Enum 정의
enum ShoulderSoundEffects: String, SoundEffectProtocol, CaseIterable {
    case star1, star2, star3, star4, star5, star6
    case entryRocket
    case shoulderTimer
    
    static var stars: [ShoulderSoundEffects] {
        allCases.filter { $0.rawValue.starts(with: "star") }
    }
}
//TODO: 손목, 눈 예시
enum WristSoundEffects: String, SoundEffectProtocol, CaseIterable {
    case ringCharge, spiralHit, wristStretch
}

enum EyeSoundEffects: String, SoundEffectProtocol, CaseIterable {
    case focusGain, distractionCut, eyeStretch
}


