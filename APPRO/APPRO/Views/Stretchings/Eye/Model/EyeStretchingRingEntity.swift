//
//  EyeStretchingRingEntity.swift
//  APPRO
//
//  Created by 정상윤 on 11/20/24.
//

import Combine
import Foundation
import RealityKit
import RealityKitContent

final class EyeStretchingRingEntity: Entity {
    
    let collisionState = CurrentValueSubject<EyeRingCollisionState, Never>(
        .init(
            restrictLineCollided: false,
            innerPlaneCollided: false
        )
    )
    
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
    
    private var audioPlaybackController: AudioPlaybackController?
    
    private var cancellableBag = Set<AnyCancellable>()
    
    required init() {
        super.init()
        
        self.transform.scale = [0.37, 0.37, 0.37]
    }
    
    func loadCoreEntity() async throws {
        let entity = try await Entity(
            named: EyeStretchingEntityType.ring.loadURL,
            in: realityKitContentBundle
        )
        
        addChild(entity)
    }
    
    func appear() throws {
        try playOpacityAnimation(from: 0.0, to: 1.0)
        
        playAudio(.appear)
    }
    
    func setCollisionComponent() async throws {
        let innerPlane = try getChild(.innerPlane)
        let restrictLine = try getChild(.restrictLine)
        
        let innerPlaneMeshResource = try generateMeshResource(modelEntityName: "Cylinder")
        let restrictLineMeshResource = try generateMeshResource(modelEntityName: "Torus")
        
        let innerPlaneShapeResource = try await ShapeResource.generateShapeResource(
            mesh: innerPlaneMeshResource,
            isConvex: true
        )
        let restrictLineShapeResource = try await ShapeResource.generateShapeResource(
            mesh: restrictLineMeshResource,
            isConvex: false
        )
        
        innerPlane.components.set(CollisionComponent(shapes: [innerPlaneShapeResource], isStatic: true))
        restrictLine.components.set(CollisionComponent(shapes: [restrictLineShapeResource], isStatic: true))
        
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
        guard let torusModelEntity = findEntity(named: "Torus") as? ModelEntity else {
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
                audioPlaybackController = try await playAudio(
                    filename: type.filename,
                    configuration: configuration
                )
            } catch {
                dump("EyeStretchingRingEntity playAudio failed: \(error)")
            }
        }
    }

}


// MARK: - Collision Subscription
extension EyeStretchingRingEntity {
    
    func subscribeCollisionEvent() throws {
        guard let scene else { throw EntityError.sceneNotFound }
        let innerPlane = try getChild(.innerPlane)
        let restrictLine = try getChild(.restrictLine)
        
        subscribeEyesInnerPlaneEvent(scene: scene, entity: innerPlane)
        subscribeEyesRestrictLineEvent(scene: scene, entity: restrictLine)
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

extension EyeStretchingRingEntity: HasChildren {
    
    enum ChildrenEntity: String {
        case innerPlane = "inner_plane"
        case restrictLine = "restrict_line"
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
