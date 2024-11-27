//
//  EyeStretchingDisturbEntity.swift
//  APPRO
//
//  Created by 정상윤 on 11/21/24.
//

import Foundation
import RealityKit
import RealityKitContent

final class EyeStretchingDisturbEntity: Entity {
    
    private let originalScale: Float3 = [0.17, 0.17, 0.17]
    private var largeScale: Float3 {
        originalScale * 1.5
    }
    
    private var audioPlaybackController: AudioPlaybackController?
    
    required init() {
        super.init()
        
        self.transform.scale = originalScale
        self.components.set(SpatialAudioComponent())
    }
    
    func loadCoreEntity(type: DisturbEntityType) async throws {
        let entity = try await Entity(
            named: EyeStretchingEntityType.disturbEntity(type: type).loadURL,
            in: realityKitContentBundle
        )
        
        addChild(entity)
    }
    
    func setGestureComponent(type: DisturbEntityType, component: Component) throws {
        guard let entity = findEntity(named: type.rawValue) else {
            throw EntityError.entityNotFound(name: type.rawValue)
        }
        
        entity.components.set(component)
    }
    
    func enlarge() {
        var transform = transform
        transform.scale = largeScale
        move(to: transform, relativeTo: nil, duration: 1.0)
        
        playAudio(.enlarge)
    }
    
    func reduce() {
        var transform = transform
        transform.scale = originalScale
        move(to: transform, relativeTo: nil, duration: 0.5)
        
        playAudio(.reduce)
    }
    
    func restoreScale() {
        var transform = transform
        transform.scale = originalScale
        move(to: transform, relativeTo: nil, duration: 1.0)
    }
    
    func appear() {
        do {
            try playOpacityAnimation(from: 0.0, to: 1.0)
            playAudio(.appear)
        } catch {
            dump("appear failed: \(error)")
        }
    }
    
    func disappear() {
        var transform = transform
        transform.scale = .zero
        move(to: transform, relativeTo: nil, duration: 0.5)
        
        playAudio(.disappear)
    }
    
    private func playAudio(_ type: DisturbEntityAudio) {
        guard let path = Bundle.main.path(forResource: type.filename, ofType: "mp3") else {
            dump("playAudio failed: \(type)")
            return
        }
        audioPlaybackController?.stop()
        Task {
            do {
                let audioResource = try await AudioFileResource(contentsOf: URL(filePath: path))
                audioPlaybackController = playAudio(audioResource)
            } catch {
                dump("playAudio failed \(type): \(error)")
            }
        }
    }
    
}

private enum DisturbEntityAudio {
    
    case appear
    case disappear
    case enlarge
    case reduce
    
    var filename: String {
        "disturb_object_\(self)"
    }
    
}
