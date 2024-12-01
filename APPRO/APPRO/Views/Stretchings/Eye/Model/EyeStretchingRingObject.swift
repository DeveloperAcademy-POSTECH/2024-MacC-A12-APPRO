//
//  EyeStretchingRingObject.swift
//  APPRO
//
//  Created by 정상윤 on 11/20/24.
//

import Combine
import Foundation
import RealityKit
import RealityKitContent

@MainActor
final class EyeStretchingRingObject {
    
    private(set) var entity = Entity()
    private let scale = Float3(0.37, 0.37, 0.37)
    private var eyesAreInside = false {
        willSet {
            if eyesAreInside != newValue {
                do {
                    try updateShaderGraphParameter(newValue)
                } catch {
                    dump("updateShaderGraphParameter failed: \(error)")
                }
            }
        }
    }
    private var innerPlaneEntity: Entity? {
        entity.findEntity(named: "inner_plane")
    }
    private var restrictLineEntity: Entity? {
        entity.findEntity(named: "restrict_line")
    }
    private var audioPlaybackController: AudioPlaybackController?
    private var cancellableBag = Set<AnyCancellable>()
    
    let collisionState = CurrentValueSubject<EyeRingCollisionState, Never>(
        .init(
            restrictLineCollided: false,
            innerPlaneCollided: false
        )
    )
    
    func loadEntity() async throws {
        self.entity = try await Entity(
            named: EyeStretchingEntityType.ring.loadURL,
            in: realityKitContentBundle
        )
        self.entity.transform.scale = scale
    }
    
    func appear() throws {
        try entity.playOpacityAnimation(from: 0.0, to: 1.0)
        
        playAudio(.appear)
    }
    
    func setCollisionComponent() async throws {
        guard let innerPlaneEntity else { throw EntityError.entityNotFound(name: "inner_plane") }
        guard let restrictLineEntity else { throw EntityError.entityNotFound(name: "restrict_line") }
        
        let innerPlaneMeshResource = try entity.generateMeshResource(modelEntityName: "Cylinder")
        let restrictLineMeshResource = try entity.generateMeshResource(modelEntityName: "Torus")
        
        let innerPlaneShapeResource = try await ShapeResource.generateShapeResource(
            mesh: innerPlaneMeshResource,
            isConvex: true
        )
        let restrictLineShapeResource = try await ShapeResource.generateShapeResource(
            mesh: restrictLineMeshResource,
            isConvex: false
        )
        
        innerPlaneEntity.components.set(CollisionComponent(
            shapes: [innerPlaneShapeResource], isStatic: true)
        )
        restrictLineEntity.components.set(CollisionComponent(
            shapes: [restrictLineShapeResource], isStatic: true)
        )
        
        handleCollisionState()
    }
    
    private func handleCollisionState() {
        collisionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.eyesAreInside = state.eyesAreInside
            }
            .store(in: &cancellableBag)
    }
    
    private func updateShaderGraphParameter(_ eyesAreInside: Bool) throws {
        guard let torusModelEntity = entity.findEntity(named: "Torus") as? ModelEntity else {
            throw EntityError.entityNotFound(name: "Torus")
        }
        
        guard var shaderGraphMaterial = torusModelEntity.components[ModelComponent.self]?.materials.first as? ShaderGraphMaterial else {
            throw EntityError.shaderGraphMaterialNotFound
        }
        
        if !eyesAreInside {
            playAudio(.collided)
        }
        
        try shaderGraphMaterial.setParameter(name: "EyesAreInside", value: .bool(eyesAreInside))
        torusModelEntity.components[ModelComponent.self]?.materials = [shaderGraphMaterial]
    }
    
    private func playAudio(
        _ type: RingEntityAudio,
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
                dump("EyeStretchingRingObject playAudio failed: \(error)")
            }
        }
    }

}


// MARK: - Collision Subscription
extension EyeStretchingRingObject {
    
    func subscribeCollisionEvent() throws {
        guard let scene = entity.scene else { throw EntityError.sceneNotFound }
        guard let innerPlaneEntity else { throw EntityError.entityNotFound(name: "inner_plane") }
        guard let restrictLineEntity else { throw EntityError.entityNotFound(name: "restrict_line") }
        
        subscribeEyesInnerPlaneEvent(scene: scene, entity: innerPlaneEntity)
        subscribeEyesRestrictLineEvent(scene: scene, entity: restrictLineEntity)
    }
    
    private func subscribeEyesInnerPlaneEvent(scene: RealityKit.Scene, entity: Entity) {
        scene.subscribe(to: CollisionEvents.Began.self, on: entity) { [weak self] _ in
            guard let self else { return }
            
            collisionState.send(collisionState.value.replacing(innerPlane: true))
        }
        .store(in: &cancellableBag)
        
        scene.subscribe(to: CollisionEvents.Ended.self, on: entity) { [weak self] _ in
            guard let self else { return }
            
            collisionState.send(collisionState.value.replacing(innerPlane: false))
        }
        .store(in: &cancellableBag)
    }
    
    private func subscribeEyesRestrictLineEvent(scene: RealityKit.Scene, entity: Entity) {
        scene.subscribe(to: CollisionEvents.Began.self, on: entity) { [weak self] _ in
            guard let self else { return }
            
            collisionState.send(collisionState.value.replacing(restrictLine: true))
        }
        .store(in: &cancellableBag)
        
        scene.subscribe(to: CollisionEvents.Ended.self, on: entity) { [weak self] _ in
            guard let self else { return }
            
            collisionState.send(collisionState.value.replacing(restrictLine: false))
        }
        .store(in: &cancellableBag)
    }
    
}

private enum RingEntityAudio {
    
    case appear
    case collided
    
    var filename: String {
        switch self {
        case .appear: 
            "ring_\(self)"
        case .collided:
            "ring_\(self)"
        }
    }
    
}
