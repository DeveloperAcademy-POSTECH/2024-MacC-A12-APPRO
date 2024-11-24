//
//  EyeStretchingEyesEntity.swift
//  APPRO
//
//  Created by 정상윤 on 11/21/24.
//

import Foundation
import Combine
import RealityKit
import RealityKitContent

final class EyeStretchingEyesEntity: Entity {
    
    private var cancellabeBag = Set<AnyCancellable>()
    
    required init() {
        super.init()
        
        self.transform.scale = [0.7, 0.7, 0.7]
    }
    
    func loadCoreEntity() async throws {
        let entity = try await Entity(
            named: EyeStretchingEntityType.eyes.loadURL,
            in: realityKitContentBundle
        )
        
        addChild(entity)
    }
    
    func setPatchComponents(_ components: [Component]) throws {
        let patch = try getChild(.patch)
        
        patch.components.set(components)
    }
    
    func removePatch() throws {
        guard let scene else { throw EntityError.sceneNotFound }
        let patch = try getChild(.patch)
        
        try patch.playOpacityAnimation(from: 1.0, to: 0.0, duration: 1.0)
        
        scene.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: patch) { event in
            patch.removeFromParent()
        }
        .store(in: &cancellabeBag)
    }
    
    func playLoopAnimation() throws {
        guard let animationResource = availableAnimations.first?.repeat() else {
            throw EntityError.availabeAnimationNotFound
        }
        
        playAnimation(animationResource)
    }
    
    func setCollisionComponent() async throws {
        let leftEye = try getChild(.leftEye)
        let rightEye = try getChild(.rightEye)
        
        let leftEyeMesh = try generateMeshResource(modelEntityName: "Cylinder_left")
        let rightEyeMesh = try generateMeshResource(modelEntityName: "Cylinder_right")
        
        let leftEyeShapeResource = try await ShapeResource.generateShapeResource(
            mesh: leftEyeMesh, isConvex: true
        )
        let rightEyeShapeResource = try await ShapeResource.generateShapeResource(
            mesh: rightEyeMesh, isConvex: true
        )
        
        leftEye.components.set(CollisionComponent(shapes: [leftEyeShapeResource]))
        rightEye.components.set(CollisionComponent(shapes: [rightEyeShapeResource]))
    }
    
}

extension EyeStretchingEyesEntity: HasChildren {
    
    enum ChildrenEntity: String {
        case leftEye = "eye_left"
        case rightEye = "eye_right"
        case patch = "patch"
    }
    
}
