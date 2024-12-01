//
//  EyeStretchingEyesObject.swift
//  APPRO
//
//  Created by 정상윤 on 11/21/24.
//

import Foundation
import Combine
import RealityKit
import RealityKitContent

@MainActor
final class EyeStretchingEyesObject {
    
    private(set) var entity = Entity()
    private let scale = Float3(0.7, 0.7, 0.7)
    private var cancellabeBag = Set<AnyCancellable>()
    
    private var audioPlaybackController: AudioPlaybackController?
    
    private var patchEntity: Entity? {
        entity.findEntity(named: "patch")
    }
    private var leftEyeEntity: Entity? {
        entity.findEntity(named: "eye_left")
    }
    private var rightEyeEntity: Entity? {
        entity.findEntity(named: "eye_right")
    }
    
    func loadEntity() async throws {
        self.entity = try await Entity(
            named: EyeStretchingEntityType.eyes.loadURL,
            in: realityKitContentBundle
        )
        
        self.entity.transform.scale = scale
        
        playAudio(
            .snoring,
            configuration: .init(
                shouldLoop: true
            )
        )
    }
    
    func setPatchComponents(_ components: [Component]) throws {
        guard let patchEntity else { throw EntityError.entityNotFound(name: "patch") }
        
        patchEntity.components.set(components)
    }
    
    func removePatch() throws {
        guard let scene = entity.scene else { throw EntityError.sceneNotFound }
        guard let patchEntity else { throw EntityError.entityNotFound(name: "patch") }
        
        try patchEntity.playOpacityAnimation(from: 1.0, to: 0.0, duration: 1.0)
        playAudio(.patchDisappear)
        
        scene.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: patchEntity) { event in
            patchEntity.removeFromParent()
        }
        .store(in: &cancellabeBag)
    }
    
    func playLoopAnimation() throws {
        guard let animationResource = entity.availableAnimations.first?.repeat() else {
            throw EntityError.availabeAnimationNotFound
        }
        
        entity.playAnimation(animationResource)
    }
    
    func setCollisionComponent() async throws {
        guard let leftEyeEntity else { throw EntityError.entityNotFound(name: "eye_left") }
        guard let rightEyeEntity else { throw EntityError.entityNotFound(name: "eye_right") }
        
        let leftEyeMesh = try entity.generateMeshResource(modelEntityName: "Cylinder_left")
        let rightEyeMesh = try entity.generateMeshResource(modelEntityName: "Cylinder_right")
        
        let leftEyeShapeResource = try await ShapeResource.generateShapeResource(
            mesh: leftEyeMesh, isConvex: true
        )
        let rightEyeShapeResource = try await ShapeResource.generateShapeResource(
            mesh: rightEyeMesh, isConvex: true
        )
        
        leftEyeEntity.components.set(CollisionComponent(shapes: [leftEyeShapeResource]))
        rightEyeEntity.components.set(CollisionComponent(shapes: [rightEyeShapeResource]))
    }
    
    private func playAudio(
        _ type: EyesEntityAudio,
        configuration: AudioFileResource.Configuration = .init()
    ) {
        Task {
            do {
                audioPlaybackController?.stop()
                audioPlaybackController = try await entity.playAudio(
                    filename: type.filename,
                    configuration: configuration
                )
            } catch {
                dump("EyeStretchingEyeEntity playAudio failed: \(error)")
            }
        }
    }
    
}

private enum EyesEntityAudio {
    
    case snoring
    case patchDisappear
    
    var filename: String {
        switch self {
        case .snoring:
            "eyes_snoring"
        case .patchDisappear:
            "patch_disappear"
        }
    }
    
}
