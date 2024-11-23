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
        
        self.transform.scale = [0.35, 0.35, 0.35]
    }
    
    func loadCoreEntity() async throws {
        let entity = try await Entity(
            named: EyeStretchingEntityType.ring.loadURL,
            in: realityKitContentBundle
        )
        
        addChild(entity)
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
    }
    
    private func updateShaderGraphParameter(_ eyesAreInside: Bool) throws {
        guard let torusModelEntity = findEntity(named: "Torus") as? ModelEntity else {
            throw EntityError.entityNotFound(name: "Torus")
        }
        
        guard var shaderGraphMaterial = torusModelEntity.components[ModelComponent.self]?.materials.first as? ShaderGraphMaterial else {
            throw EntityError.shaderGraphMaterialNotFound
        }
        
        try shaderGraphMaterial.setParameter(name: "EyesAreInside", value: .bool(eyesAreInside))
        torusModelEntity.components[ModelComponent.self]?.materials = [shaderGraphMaterial]
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

extension EyeStretchingRingEntity: HasChildren {
    
    enum ChildrenEntity: String {
        case innerPlane = "inner_plane"
        case restrictLine = "restrict_line"
    }
    
}

private struct EyeRingCollisionState {
    
    var restrictLineCollided: Bool
    var innerPlaneCollided: Bool
    
    var eyesAreInside: Bool {
        innerPlaneCollided && !restrictLineCollided
    }
    
}
