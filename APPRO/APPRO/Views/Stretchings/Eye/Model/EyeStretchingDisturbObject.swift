//
//  EyeStretchingDisturbObject.swift
//  APPRO
//
//  Created by 정상윤 on 11/21/24.
//

import Foundation
import RealityKit
import RealityKitContent

final class EyeStretchingDisturbObject {
    
    private(set) var entity = Entity()
     
    private let type: DisturbEntityType
    private let originalScale: Float3 = [0.1, 0.1, 0.1]
    private var largeScale: Float3 { originalScale * 1.5 }
    
    private var audioPlaybackController: AudioPlaybackController?
    
    var clone: EyeStretchingDisturbObject {
        .init(
            type: type,
            entity: entity.clone(recursive: true)
        )
    }
    
    init(type: DisturbEntityType) {
        self.type = type
    }
    
    convenience init(type: DisturbEntityType, entity: Entity) {
        self.init(type: type)
        self.entity = entity
        
        configureEntity()
    }
    
    func loadEntity() async throws {
        self.entity = try await Entity(
            named: EyeStretchingEntityType.disturbEntity(type: type).loadURL,
            in: realityKitContentBundle
        )
        configureEntity()
    }
    
    func setPosition(_ position: Float3, relativeTo referenceEntity: Entity) {
        entity.setPosition(
            position / referenceEntity.scale,
            relativeTo: referenceEntity
        )
        entity.transform.rotation = .init(
            angle: Float.random(in: -0.4...0.4),
            axis: [0, 0, 1]
        )
    }
    
    func setGestureComponent(_ component: Component) throws {
        guard let entity = entity.findEntity(named: type.rawValue) else {
            throw EntityError.entityNotFound(name: type.rawValue)
        }
        
        entity.components.set(component)
    }
    
    func enlarge() {
        var transform = entity.transform
        transform.scale = largeScale
        entity.move(to: transform, relativeTo: nil, duration: 1.0)
        
        playAudio(.enlarge)
    }
    
    func reduce() {
        var transform = entity.transform
        transform.scale = originalScale
        entity.move(to: transform, relativeTo: nil, duration: 0.5)
        
        playAudio(.reduce)
    }
    
    func restoreScale() {
        var transform = entity.transform
        transform.scale = originalScale
        entity.move(to: transform, relativeTo: nil, duration: 1.0)
    }
    
    func appear() {
        do {
            try entity.playOpacityAnimation(from: 0.0, to: 1.0)
            playAudio(.appear)
        } catch {
            dump("appear failed: \(error)")
        }
    }
    
    func disappear() {
        var transform = entity.transform
        transform.scale = .zero
        entity.move(to: transform, relativeTo: nil, duration: 0.5)
        
        playAudio(.disappear)
    }

private extension EyeStretchingDisturbObject {
    
    func configureEntity() {
        entity.transform.scale = originalScale
        
        setComponents()
    }
    
    func setComponents() {
        entity.components.set([
            SpatialAudioComponent(),
            OpacityComponent(opacity: 0.0),
            InputTargetComponent(allowedInputTypes: .indirect),
            HoverEffectComponent(.spotlight(.default))
        ])
    }
    
    func playAudio(_ type: DisturbEntityAudio) {
        Task { @MainActor in
            do {
                audioPlaybackController?.stop()
                audioPlaybackController = try await entity.playAudio(filename: type.filename)
            } catch {
                dump("EyeStretchingDisturbObject playAudio failed: \(error)")
            }
        }
    }
    
}

extension EyeStretchingDisturbObject: Equatable {
    
    static func == (
        lhs: EyeStretchingDisturbObject,
        rhs: EyeStretchingDisturbObject
    ) -> Bool {
        lhs.entity == rhs.entity
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
