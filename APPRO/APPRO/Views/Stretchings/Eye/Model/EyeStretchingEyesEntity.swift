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
    
    private var leftEye: Entity? {
        self.findEntity(named: "eye_left")
    }
    
    private var rightEye: Entity? {
        self.findEntity(named: "eye_right")
    }
    
    private var patch: Entity? {
        self.findEntity(named: "patch")
    }
    
    private var cancellabeBag = Set<AnyCancellable>()
    
    required init() {
        super.init()
    }
    
    func loadCoreEntity() async throws {
        let entity = try await Entity(
            named: EyeStretchingEntityType.eyes.loadURL,
            in: realityKitContentBundle
        )
        self.children.append(entity)
    }
    
    func setPatchHoverEffectComponent() throws {
        guard let patch else { throw EyeStretchingError.entityNotFound(name: "patch") }
        
        patch.components.set(HoverEffectComponent(.highlight(.default)))
    }
    
    func removePatch() throws {
        guard let patch else { throw EyeStretchingError.entityNotFound(name: "patch") }
        guard let scene else { throw EyeStretchingError.sceneNotFound }
        
        try patch.playOpacityAnimation(from: 1.0, to: 0.0, duration: 1.0)
        
        scene.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: patch) { event in
            patch.removeFromParent()
        }
        .store(in: &cancellabeBag)
    }
    
    func playLoopAnimation() throws {
        guard let animationResource = availableAnimations.first?.repeat() else {
            throw EyeStretchingError.availabeAnimationNotFound
        }
        
        playAnimation(animationResource)
    }
    
    func setCollisionComponent() async throws {
        guard let leftEye else { throw EyeStretchingError.entityNotFound(name: "eye_left") }
        guard let rightEye else { throw EyeStretchingError.entityNotFound(name: "eye_right") }
        
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
