//
//  Untitled.swift
//  PracticeVisionOS
//
//  Created by 정상윤 on 10/16/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct EyeStretchingView: View {
    
    @StateObject private var headTracker = HeadTracker()
    
    @State private var ballEntities = [Entity]()
    @State private var cubeEntities = [Entity]()
    @State private var indexList = Array(0..<8).shuffled() {
        didSet {
            update()
        }
    }
    
    var body: some View {
        RealityView { content in
            do {
                let rootEntity = try await Entity(named: "Scene", in: realityKitContentBundle)
                
                configureBallEntities(rootEntity: rootEntity, content: &content)
                configureCubeEntities(rootEntity: rootEntity, content: &content)
                configureCenterSphereEntity(rootEntity: rootEntity, content: &content)
                try await configureRingEntity(rootEntity: rootEntity, content: &content)
                
                content.add(rootEntity)
            } catch {
                dump(error)
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    guard let lastIndex = indexList.last else { return }
                    if value.entity.name == "ball_\(lastIndex)" {
                        Task {
                            moveBallShrink(entity: ballEntities[lastIndex])
                            moveCubeExpand(entity: cubeEntities[lastIndex])
                            await playPopAudio(ballEntity: value.entity)
                            indexList.removeLast()
                        }
                    }
                }
        )
    }
    
    private func configureBallEntities(rootEntity: Entity, content: inout RealityViewContent) {
        ballEntities = (0..<8).compactMap { rootEntity.findEntity(named: "ball_\($0)") }
        ballEntities.enumerated().forEach { index, entity in
            guard let lastIndex = indexList.last else { return }
            
            entity.components.set(HoverEffectComponent(.highlight(.default)))
            entity.components.set(OpacityComponent(opacity: index == lastIndex ? Float(1.0) : Float(0.1)))
        }
    }
    
    private func configureCubeEntities(rootEntity: Entity, content: inout RealityViewContent) {
        cubeEntities = (0..<8).compactMap { rootEntity.findEntity(named: "cube_\($0)") }
    }
    
    private func configureCenterSphereEntity(rootEntity: Entity, content: inout RealityViewContent) {
        let sphere = Entity()
        sphere.name = "CenterSphere"
        let radius = Float(0.11)
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let floatingSphere = ModelEntity(
            mesh: .generateSphere(radius: radius),
            materials: [material]
        )
        let distance = Float(2.5)
        
        sphere.addChild(floatingSphere)
        
        sphere.components.set(ClosureComponent(closure: { deltaTime in
            guard let currentTransform = headTracker.originFromDeviceTransform() else { return }
            
            let targetPosition = currentTransform.translation() - distance * currentTransform.forward()
            let ratio = Float(pow(0.96, deltaTime / (16 * 1E-3)))
            let newPosition = ratio * sphere.position(relativeTo: nil) + (1 - ratio) * targetPosition
            
            sphere.setPosition(newPosition, relativeTo: nil)
        }))
        
        sphere.components.set(CollisionComponent(shapes: [.generateSphere(radius: radius)], mode: .default))
        
        content.add(sphere)
    }
    
    private func configureRingEntity(rootEntity: Entity, content: inout RealityViewContent) async throws {
        guard let ringEntity = rootEntity.findEntity(named: "ring"),
              let torusModelEntity = ringEntity.findEntity(named: "Torus_002") as? ModelEntity,
              let meshResource = torusModelEntity.model?.mesh else { return }
        
        let shape = try await ShapeResource.generateStaticMesh(from: meshResource)
        
        torusModelEntity.components.set(CollisionComponent(shapes: [shape], mode: .default))
        
        _ = content.subscribe(to: CollisionEvents.Began.self, on: torusModelEntity) { event in
            setTorusMaterialParameter(torusModelEntity: torusModelEntity, isCollided: true)
        }
        
        _ = content.subscribe(to: CollisionEvents.Ended.self, on: torusModelEntity) { event in
            setTorusMaterialParameter(torusModelEntity: torusModelEntity, isCollided: false)
        }
    }
    
    private func setTorusMaterialParameter(torusModelEntity: ModelEntity, isCollided: Bool) {
        guard var material = torusModelEntity.components[ModelComponent.self]?.materials.first as? ShaderGraphMaterial else {
            dump("ShaderGraphMaterial for \(torusModelEntity.name) not found.")
            return
        }
        do {
            try material.setParameter(name: "TorusColor", value: isCollided ? .color(.red) : .color(.white))
            torusModelEntity.components[ModelComponent.self]?.materials = [material]
        } catch {
            dump(error)
        }
    }
    
    private func update() {
        guard let lastIndex = indexList.last else { return }
        
        appear(entity: ballEntities[lastIndex])
    }
    
    private func appear(entity: Entity) {
        let animationDefinition = FromToByAnimation(from: Float(0.1), to: Float(1.0), bindTarget: .opacity)
        
        do {
            let animationResource = try AnimationResource.generate(with: animationDefinition)
            entity.playAnimation(animationResource)
        } catch {
            dump(error)
        }
    }
    
    private func moveBallShrink(entity: Entity) {
        var transform = entity.transform
        transform.scale = .init(x: 0, y: 0, z: 0)
        entity.move(to: transform, relativeTo: entity.parent, duration: 1.0)
    }
    
    private func moveCubeExpand(entity: Entity) {
        var transform = entity.transform
        transform.scale = .init(x: 0.15, y: 0.15, z: 0.15)
        entity.move(to: transform, relativeTo: entity.parent, duration: 1.0)
    }
    
    private func playPopAudio(ballEntity: Entity) async {
        do {
            let resource = try await AudioFileResource(
                named: "/Root/PopSound",
                from: "Scene.usda",
                in: realityKitContentBundle
            )
            ballEntity.prepareAudio(resource).play()
        } catch {
            dump(error)
        }
    }
    
}
