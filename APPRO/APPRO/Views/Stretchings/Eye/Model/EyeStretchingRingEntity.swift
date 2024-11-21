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
    
    private var innerPlane: Entity? {
        self.findEntity(named: "inner_plane")
    }
    
    private var restrictLine: Entity? {
        self.findEntity(named: "restrict_line")
    }
    
    private var collisionState = EyeRingCollisionState(
        restrictLineCollided: false,
        innerPlaneCollided: false
    ) {
        didSet {
            do {
                try updateShaderGraphParameter(collisionState.eyesAreInside)
            } catch {
                dump(error)
            }
        }
    }
    
    private var cancellableBag = Set<AnyCancellable>()
    
    required init() {
        super.init()
    }
    
    func configure() async throws {
        let entity = try await Entity(
            named: EyeStretchingEntityType.ring.loadURL,
            in: realityKitContentBundle
        )
        self.children.append(entity)
        
        try await setCollisionComponent()
    }
    
    private func updateShaderGraphParameter(_ eyesAreInside: Bool) throws {
        guard let torusModelEntity = self.findEntity(named: "Torus") as? ModelEntity else {
            throw EyeStretchingError.entityNotFound(name: "Torus")
        }
        guard var shaderGraphMaterial = torusModelEntity.components[ModelComponent.self]?.materials.first as? ShaderGraphMaterial else {
            dump("updateShaderGraphParameter failed: ShaderGraphMaterial not found")
            return
        }
        do {
            try shaderGraphMaterial.setParameter(name: "EyesAreInside", value: .bool(eyesAreInside))
            torusModelEntity.components[ModelComponent.self]?.materials = [shaderGraphMaterial]
        } catch {
            dump("updateShaderGraphParameter failed: \(error)")
        }
    }

}


// MARK: - Collision Subscription
extension EyeStretchingRingEntity {
    
    func subscribeCollisionEvent() {
        guard let innerPlane, let restrictLine else {
            dump("subscribeCollisionEvent failed: No innerPlane or restrictLine found")
            return
        }
        guard let scene = self.scene else {
            dump("subscribeCollisionEvent failed: Scene is not found")
            return
        }
        subscribeEyesInnerPlaneEvent(scene: scene, entity: innerPlane)
        subscribeEyesRestrictLineEvent(scene: scene, entity: restrictLine)
    }
    
    private func subscribeEyesInnerPlaneEvent(scene: RealityKit.Scene, entity: Entity) {
        scene.subscribe(to: CollisionEvents.Began.self, on: entity) { [weak self] _ in
            self?.collisionState.innerPlaneCollided = true
        }
        .store(in: &cancellableBag)
        
        scene.subscribe(to: CollisionEvents.Ended.self, on: entity) { [weak self] _ in
            self?.collisionState.innerPlaneCollided = false
        }
        .store(in: &cancellableBag)
    }
    
    private func subscribeEyesRestrictLineEvent(scene: RealityKit.Scene, entity: Entity) {
        scene.subscribe(to: CollisionEvents.Began.self, on: entity) { [weak self] _ in
            self?.collisionState.restrictLineCollided = true
        }
        .store(in: &cancellableBag)
        
        scene.subscribe(to: CollisionEvents.Ended.self, on: entity) { [weak self] _ in
            self?.collisionState.restrictLineCollided = false
        }
        .store(in: &cancellableBag)
    }
    
}

// MARK: - Collision Shape
private extension EyeStretchingRingEntity {
    
    func setCollisionComponent() async throws {
        guard let innerPlane else { throw EyeStretchingError.entityNotFound(name: "inner_plane") }
        guard let restrictLine else { throw EyeStretchingError.entityNotFound(name: "restrict_line") }
        
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
    }
    
}

private struct EyeRingCollisionState {
    
    var restrictLineCollided: Bool
    var innerPlaneCollided: Bool
    
    var eyesAreInside: Bool {
        innerPlaneCollided && !restrictLineCollided
    }
    
}
