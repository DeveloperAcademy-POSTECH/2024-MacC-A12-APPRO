//
//  HandRollingImmersiveView.swift
//  APPRO
//
//  Created by marty.academy on 10/20/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

struct HandRollingImmersiveView: View {
    
    @State private var gestureModel = HandGestureModel()
    
    @State var launchModels: [Entity] = []
    @State var orbitBalls: Entity = Entity()
    
    @State private var collisionEventSubscription: EventSubscription?
    
    @State private var objIndex: Int = 1
    
    init() {
        dump("HandRollingImmersiveView init")
    }
    
    var body: some View {
        RealityView { content in
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
            }
            
            orbitBalls = try! await getOrbitBalls()
                            
            addEntities(content)
            
            collisionEventSubscription = content.subscribe(to: CollisionEvents.Began.self, on: nil) { collision in
                let entityA = collision.entityA as! ModelEntity
                let entityB = collision.entityB as! ModelEntity
                
                Task {
                    do {
                        try await playCollisionAudio(entityA)
                        
                        for entity in [entityA, entityB] {
                            deleteEntityFewSecondsLater(entity)
                            changeEntityColor(modelEntity: entity)
                        }
                    } catch {
                        dump(error)
                    }
                }
            }
            
        } update: { content in
            guard let orbitBallEntity = content.entities.first(where: {$0.name == "OrbitBalls"}) else { return }
            orbitBallEntity.transform = calArmTransform(orbitBallEntity.transform)
            
            addEntities(content)
        }
        .task {
            await gestureModel.start()
        }
        .task {
            await gestureModel.publishHandTrackingUpdates()
        }
        .task {
            await gestureModel.monitorSessionEvents()
        }
        .onChange(of: gestureModel.rotationCount, initial: false ) { _, rotationCount in
            Task {
                do {
                    try await launchModels.append(generateLaunchObj())
                    try await animatingLaunchObj()
                } catch {
                    dump(error)
                }
            }
        }
    }
    
    private func changeEntityColor(modelEntity: Entity) {
        guard var modelComponent = modelEntity.components[ModelComponent.self],
              var shaderGraphMaterial = modelComponent.materials.first as? ShaderGraphMaterial
        else { return }
        
        do {
            try shaderGraphMaterial.setParameter(name: "ChangedTo", value: .int(Int32.random(in: 0..<10)))
            modelComponent.materials = [shaderGraphMaterial]
            modelEntity.components.set(modelComponent)
        } catch {}
    }
    
    private func calArmTransform(_ beforeTransform: Transform) -> Transform {
        guard let anchor = gestureModel.latestHandTracking.right else { return beforeTransform }
        let joint = anchor.handSkeleton?.joint(.forearmWrist)
        
        if ((joint?.isTracked) != nil) {
            let t = matrix_multiply(anchor.originFromAnchorTransform, (joint?.anchorFromJointTransform)!)
            
            var transform = Transform(matrix: t)
            transform.scale = beforeTransform.scale
            
            return transform
        }
        return beforeTransform
        
    }
    
    private func addEntities(_ content: RealityViewContent) {
        for entity in launchModels {
            content.add(entity)
        }
        
        if objIndex == 1 { // 사용자가 손목을 돌리는 것에 대해서 캐치하고 나면, 가이드가 필요없게 된다.
            content.add(orbitBalls)
        }
    }
    
    private func deleteEntityFewSecondsLater(_ entity:Entity) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5 ) {
            entity.removeFromParent()
            launchModels.removeAll(where: {$0.name == entity.name} )
        }
    }
    
    private func getOrbitBalls() async throws -> Entity {
        if let orbitBalls = try? await Entity(named: "wrist_ball", in: realityKitContentBundle) {
            orbitBalls.name = "OrbitBalls"
            orbitBalls.components.set(GroundingShadowComponent(castsShadow: true))
            orbitBalls.components.set(InputTargetComponent())
            
            orbitBalls.scale = .init(repeating: 0.01)
            
            orbitBalls.generateCollisionShapes(recursive: false)
            
            guard let animationResource = orbitBalls.availableAnimations.first else { return Entity() }
            
            do {
                let animation = try AnimationResource.generate(with: animationResource.repeat().definition)
                orbitBalls.playAnimation(animation)
            } catch {
                dump(error)
            }
            
            return orbitBalls
        }
        return Entity()
    }
    
    func generateLaunchObj() async throws -> Entity {
        if let custom3DObject = try? await Entity(named: "spiral_consistent", in: realityKitContentBundle) {
            custom3DObject.name = "spiral_\(objIndex)"
            objIndex += 1
            
            custom3DObject.components.set(GroundingShadowComponent(castsShadow: true))
            custom3DObject.components.set(InputTargetComponent())
            
            custom3DObject.generateCollisionShapes(recursive: true)
            
            custom3DObject.scale = .init(repeating: 0.01)
            
            let physicsMaterial = PhysicsMaterialResource.generate(
                staticFriction: 10.00,
                dynamicFriction: 10.00,
                restitution: 10.0
            )
            
            var physicsBody = PhysicsBodyComponent(massProperties: .default, material: physicsMaterial, mode: .dynamic)
            physicsBody.isAffectedByGravity = false
            physicsBody.massProperties.mass = 0.01
            
            if let forearmWristJoint = gestureModel.latestHandTracking.right?.handSkeleton?.joint(.forearmWrist) {
                let multiplication = matrix_multiply(gestureModel.latestHandTracking.right!.originFromAnchorTransform, forearmWristJoint.anchorFromJointTransform)
                custom3DObject.position = Transform(matrix: multiplication).translation
            }
            
            if let forearmJoin = gestureModel.latestHandTracking.right?.handSkeleton?.joint(.forearmArm) {
                let multiplication = matrix_multiply(gestureModel.latestHandTracking.right!.originFromAnchorTransform, forearmJoin.anchorFromJointTransform)
                let currentRotation = simd_quatf(multiplication)
                
                let rotationAngle = Float.pi / 2
                let yAxis = simd_float3(0, 1, 0)
                let rotationQuaternion = simd_quatf(angle: rotationAngle, axis: yAxis)
                
                let newRotation = simd_mul(rotationQuaternion, currentRotation)
                
                custom3DObject.transform.rotation = newRotation
                
                let forwardDirection = multiplication.columns.0 // x axis
                let direction = simd_float3(forwardDirection.x, forwardDirection.y, forwardDirection.z)
                
                if let modelEntity = custom3DObject.findEntity(named: "Spiral_002") as? ModelEntity {
                    modelEntity.addForce(direction, relativeTo: custom3DObject)
                    modelEntity.components[PhysicsBodyComponent.self] = physicsBody
                }
            }
            
            return custom3DObject
        }
        
        return Entity()
    }
    
    func playSpatialAudio(_ entity: Entity) async throws {
        guard let entity = entity.findEntity(named: "AppearSpatialAudio"),
              let resource = try? await AudioFileResource(named: "/Root/spiral_come_out_wav",
                                                          from: "spiral_consistent.usd",
                                                          in: realityKitContentBundle) else { return }
        
        let audioPlayer = entity.prepareAudio(resource)
        audioPlayer.play()
    }
    
    func playCollisionAudio(_ modelEntity: ModelEntity) async throws {
        guard let entity = modelEntity.parent?.parent?.parent else { return }
        
        guard let spatialAudioEntity = entity.findEntity(named: "CollisionSpatialAudio"),
              let resource = try? await AudioFileResource(named: "/Root/spiral_collide_wav",
                                                          from: "spiral_consistent.usd",
                                                          in: realityKitContentBundle) else { return }
        
        let audioPlayer = spatialAudioEntity.prepareAudio(resource)
        audioPlayer.play()
    }
    
    func animatingLaunchObj() async throws {
        if let spiral = launchModels.last {
            guard let animationResource = spiral.availableAnimations.first else { return }
            
            do {
                let animation = try AnimationResource.generate(with: animationResource.repeat(count: 1).definition)
                spiral.playAnimation(animation)
            } catch {
                dump(error)
            }
            
            guard let forearmJoint = gestureModel.latestHandTracking.right?.handSkeleton?.joint(.forearmArm) else {return}
            
            let multiplication = matrix_multiply(gestureModel.latestHandTracking.right!.originFromAnchorTransform, forearmJoint.anchorFromJointTransform)
            let forwardDirection = multiplication.columns.0 // x axis
            let direction = simd_float3(forwardDirection.x, forwardDirection.y, forwardDirection.z)
            
            let moveTargetPosition = spiral.position + direction * 1.25
            
            var shortTransform = spiral.transform
            shortTransform.scale = .init(repeating: 0.1)
            
            var newTransform = spiral.transform
            newTransform.translation = moveTargetPosition
            newTransform.scale = .init(repeating: 1)
            
            let goInDirection = FromToByAnimation<Transform> (
                name: "launchFromWrist",
                from: shortTransform,
                to: newTransform,
                duration: 2,
                bindTarget: .transform
            )
            
            let animation = try AnimationResource.generate(with: goInDirection)
            
            spiral.playAnimation(animation, transitionDuration: 2)
            try await playSpatialAudio(spiral)
        }
    }
}
