//
//  HandRollingStretchingViewModel.swift
//  APPRO
//
//  Created by marty.academy on 10/31/24.
//

import SwiftUI
import ARKit
import RealityKit
import RealityKitContent

@Observable
@MainActor
final class HandRollingStretchingViewModel {
    
    //AR Session for hand tracking
    let session = ARKitSession()
    var handTracking = HandTrackingProvider()
    
    var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    
    var isRightHandInFist = false
    var isLeftHandInFist = false
    
    let threshold: Float = 0.1
    
    let frameInterval = 3
    var frameIndex = 0
    
    //RealityViewContent
    var orb = ModelEntity()
    
    var indexJointEntity = ModelEntity()
    
    var leftEntities: [Entity] = []
    var rightEntities: [Entity] = []
    
    var showGuideRing: Bool = false
    
    var rightGuideRing = Entity()
    var rightGuideSphere = ModelEntity()
    
    var leftGuideRing = Entity()
    var leftGuideSphere = ModelEntity()
    
    let radius: Float = 0.1
    
    var rightRotationForLaunchName : Int = 0
    var rightRotationCount: Int = 0
    var rightRotationCollisionArray = [ false, false, false, false]
    
    var leftRotationForLaunchName : Int = 0
    var leftRotationCount: Int = 0
    var leftRotationCollisionArray = [ false, false, false, false]
    
    var rightLaunchState = false
    var leftLaunchState = false
    
    var rightTargets = [Entity()]
    var leftTargets = [Entity()]
    
    var score = 0
    
    func makeFirstEntitySetting (_ content: RealityViewContent) async {
        rightGuideRing = await generateGuideRing(chirality: .right)
        rightGuideSphere = generateGuideSphere(chirality: .right)
        
        leftGuideRing = await generateGuideRing(chirality: .left)
        leftGuideSphere = generateGuideSphere(chirality: .left)
        
        rightTargets = await bringTargetEntities([2,1,4], chirality: .right)
        rightTargets.forEach { content.add($0)}
        
        leftTargets = await bringTargetEntities([4,2,1], chirality: .left)
        leftTargets.forEach { content.add($0)}
    }
    
    func addEntity(_ content: RealityViewContent) {
        for entity in rightEntities {
            content.add(entity)
        }
        
        for entity in leftEntities {
            content.add(entity)
        }
    }
    
    func generateGuideRing(chirality : Chirality) async  -> Entity  {
        guard let guideRingEntity = try? await Entity(named: "Hand/wrist_ring", in: realityKitContentBundle) else { return Entity() }
        guideRingEntity.name = chirality == .right ?  "Ring_Right" : "Ring_Left"
        
        if chirality == .left {
            guard let modelEntity = guideRingEntity.findEntity(named: "Torus") else {return guideRingEntity}
            
            guard var modelComponent = modelEntity.components[ModelComponent.self],
                  var shaderGraphMaterial = modelComponent.materials.first as? ShaderGraphMaterial
            else { return guideRingEntity }
            
            do {
                try shaderGraphMaterial.setParameter(name: "RingColor", value: .int(1))
                modelComponent.materials = [shaderGraphMaterial]
                modelEntity.components.set(modelComponent)
            } catch {}
            
        }
        
        return guideRingEntity
    }
    
    func generateGuideSphere(chirality : Chirality)-> ModelEntity  {
        let guideSphereEntity = ModelEntity(mesh: .generateSphere(radius: 0.02), materials: [SimpleMaterial(color: .red, roughness: 0.0, isMetallic: false)]) // var to let
        guideSphereEntity.name = chirality == .right ? "GuideSphere_Right" : "GuideSphere_Left"
        guideSphereEntity.generateCollisionShapes(recursive: false)
        
        return guideSphereEntity
    }
    
    func bringTargetEntities (_ targetRotationCounts: [Int], chirality: Chirality) async -> [Entity] {
        var targetTransforms = chirality == .left ? await getLeftHandTargetTransform() : await getRightHandTargetTransform()
        let resourceUrl = chirality == .left ? "Hand/target_blue" : "Hand/target_green"
        
        var result: [Entity] = []
        
        for targetScore in targetRotationCounts {
            guard let greenTargetEntity = try? await Entity(named: resourceUrl, in: realityKitContentBundle) else { return [] }
            let entityName = chirality == .left ? "BlueTarget_left_\(targetScore)" :"GreenTarget_right_\(targetScore)"
            
            greenTargetEntity.name = entityName
            greenTargetEntity.transform = targetTransforms.removeFirst()
            
            for index in 1...5  {
                if index != targetScore {
                    let entity = greenTargetEntity.findEntity(named: "Text_\(index)")
                    entity?.isEnabled = false
                }
            }
            result.append(greenTargetEntity)
        }
        return result
    }
    
    
    private func getRightHandTargetTransform() async -> [Transform] {
        guard let greenTargetEntity = try? await Entity(named: "Hand/target_green", in: realityKitContentBundle) else { return [Transform()] }
        
        let originalTransform = greenTargetEntity.transform
        
        var transform_1 = originalTransform
        transform_1.translation = .init(x: -0.4, y: 1.2, z: -0.5)
        transform_1.rotation = getRotationCalculator(transform_1.rotation, rotationX: 0, rotationY: -1/6 * .pi, rotationZ: 0)
        
        var transform_2  = originalTransform
        transform_2.translation = .init(x: -0.7, y: 1.4, z: -1.0)
        transform_2.rotation = getRotationCalculator(transform_2.rotation, rotationX: -1/6 * .pi, rotationY: -1/6 * .pi, rotationZ: 0)
        
        var transform_3  = originalTransform
        transform_3.translation = .init(x: 0.6, y: 1.4, z: -0.7)
        transform_3.rotation = getRotationCalculator(transform_3.rotation, rotationX: -1/6 * .pi, rotationY: 1/6 * .pi, rotationZ: 1/3 * .pi)
        
        
        return [transform_1, transform_2, transform_3]
    }
    
    private func getLeftHandTargetTransform() async -> [Transform] {
        guard let greenTargetEntity = try? await Entity(named: "Hand/target_blue", in: realityKitContentBundle) else { return [Transform()] }
        
        let originalTransform = greenTargetEntity.transform
        
        var transform_1 = originalTransform
        transform_1.translation = .init(x: -0.2, y: 1.4, z: -1.0)
        transform_1.rotation = getRotationCalculator(transform_1.rotation, rotationX: 0, rotationY: -1/6 * .pi, rotationZ: 0)
        
        var transform_2  = originalTransform
        transform_2.translation = .init(x: 0.2, y: 1.4, z: -1.0)
        transform_2.rotation = getRotationCalculator(transform_2.rotation, rotationX: 1/6 * .pi, rotationY: 1/6 * .pi, rotationZ: 0)
        
        var transform_3  = originalTransform
        transform_3.translation = .init(x: 0.7, y: 1.0, z: -0.6)
        transform_3.rotation = getRotationCalculator(transform_3.rotation, rotationX: -1/6 * .pi, rotationY: 1/6 * .pi, rotationZ: 1/3 * .pi)
        
        
        return [transform_1, transform_2, transform_3]
    }
    
    
    private func getRotationCalculator(_ currentRotation: simd_quatf, rotationX: Float, rotationY: Float, rotationZ: Float) -> simd_quatf {
        let localXAxis = normalize(currentRotation.act(SIMD3<Float>(1, 0, 0)))
        let localYAxis = normalize(currentRotation.act(SIMD3<Float>(0, 1, 0)))
        let localZAxis = normalize(currentRotation.act(SIMD3<Float>(0, 0, 1)))
        
        let rotationXQuat = simd_quatf(angle: rotationX, axis: localXAxis)
        let rotationYQuat = simd_quatf(angle: rotationY, axis: localYAxis)
        let rotationZQuat = simd_quatf(angle: rotationZ, axis: localZAxis)
        
        return currentRotation * rotationXQuat * rotationYQuat * rotationZQuat
    }
}
