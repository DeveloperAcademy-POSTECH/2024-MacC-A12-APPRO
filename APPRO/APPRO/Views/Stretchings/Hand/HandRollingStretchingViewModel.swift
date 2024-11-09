//
//  HandRollingStretchingViewModel.swift
//  APPRO
//
//  Created by marty.academy on 10/31/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

@Observable
@MainActor
final class HandRollingStretchingViewModel: StretchingCounter {
    //AR Session for hand tracking
    let session = ARKitSession()
    let sessionForWorldTracking = ARKitSession()
    
    var handTracking = HandTrackingProvider()
    var worldTracking = WorldTrackingProvider()
    
    var startingHeight: Float = 0.0
    
    var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    
    var isStartingObjectVisible = true
    var startObject: Entity = Entity()
    
    var isRightHandInFist = false
    var isLeftHandInFist = false
    
    var fistReaderRight: [Bool] = []
    var fistReaderLeft: [Bool] = []
    
    let stretchingAttachmentViewID  = "StretchingAttachmentView"
    
    let frameInterval = 1
    var frameIndex = 0
    
    //StretchingCounter
    var doneCount = 0
    var maxCount = StretchingPart.wrist.maxCount
    
    //RealityViewContent
    var leftEntities: [Entity] = []
    var rightEntities: [Entity] = []
    
    var leftTargetEntities : [Entity] = []
    var rightTargetEntities : [Entity] = []
    
    var areTargetTranslationUpdated = false
    
    var rightGuideRing = Entity()
    var rightGuideSphere = ModelEntity()
    
    var leftGuideRing = Entity()
    var leftGuideSphere = ModelEntity()
    
    let radius: Float = 0.1
    
    var rightRotationForLaunchNumber : Int = 0
    var rightRotationCount: Int = 0
    var rightRotationCollisionArray = [ false, false, false, false]
    
    var leftRotationForLaunchNumber : Int = 0
    var leftRotationCount: Int = 0
    var leftRotationCollisionArray = [ false, false, false, false]
    
    var rightLaunchState = false
    var leftLaunchState = false
    
    var leftHitCount = 0
    var rightHitCount = 0
    
    func makeFirstEntitySetting (_ content: RealityViewContent) async {
        rightGuideRing = await generateGuideRing(chirality: .right)
        rightGuideSphere = generateGuideSphere(chirality: .right)
        
        leftGuideRing = await generateGuideRing(chirality: .left)
        leftGuideSphere = generateGuideSphere(chirality: .left)
        
        rightTargetEntities = await bringTargetEntities([2,1,4], chirality: .right)
        
        leftTargetEntities = await bringTargetEntities([4,2,1], chirality: .left)
    }
    
    func addEntity(_ content: RealityViewContent) {
        for entity in rightEntities {
            content.add(entity)
        }
        
        for entity in leftEntities {
            content.add(entity)
        }
        
        if !isStartingObjectVisible {
            for entity in rightTargetEntities {
                content.add(entity)
            }
            
            for entity in leftTargetEntities {
                content.add(entity)
            }
        }
    }
    
    func generateStartingObject(_ content: RealityViewContent) async {
        guard let entity = try? await Entity(named: "Hand/main_obj_applied", in: realityKitContentBundle) else { return }
        entity.name = "StartingObject"
        
        startObject = entity
        startObject.transform.translation = .init(x: 0, y: startingHeight, z: -1.0)
        
        guard let animation = startObject.availableAnimations.first else {return}
        startObject.playAnimation(animation.repeat(duration: .infinity), transitionDuration: 6.9, startsPaused: false)
        
        content.add(entity)
    }
    
    func getRidOfStartingObject () {
        startObject.removeFromParent()
    }
    
    func generateGuideRing(chirality : Chirality) async  -> Entity  {
        guard let guideRingEntity = try? await Entity(named: "Hand/wrist_ring", in: realityKitContentBundle) else { return Entity() }
        guideRingEntity.name = chirality == .right ?  "Ring_Right" : "Ring_Left"
        
        if chirality == .left {
            getDifferentRingColor(guideRingEntity, intChangeTo: 1)
        }
        
        return guideRingEntity
    }
    
    func generateGuideSphere(chirality : Chirality)-> ModelEntity  {
        let guideSphereEntity = ModelEntity(mesh: .generateSphere(radius: 0.015), materials: [SimpleMaterial(color: .red, roughness: 0.0, isMetallic: false)]) // var to let
        guideSphereEntity.name = chirality == .right ? "GuideSphere_Right" : "GuideSphere_Left"
        guideSphereEntity.generateCollisionShapes(recursive: false)
        
        return guideSphereEntity
    }
    
    func bringTargetEntities (_ targetRotationCounts: [Int], chirality: Chirality) async -> [Entity] {
        var targetTransforms = chirality == .left ? await getLeftHandTargetTransform() : await getRightHandTargetTransform()
        let resourceUrl = chirality == .left ? "Hand/target_new_blue" : "Hand/target_new_green"
        
        var result: [Entity] = []
        
        for targetScore in targetRotationCounts {
            guard let targetEntity = try? await Entity(named: resourceUrl, in: realityKitContentBundle) else { return [] }
            let entityName = chirality == .left ? "BlueTarget_left_\(targetScore)" :"GreenTarget_right_\(targetScore)"
            
            targetEntity.name = entityName
            targetEntity.transform = targetTransforms.removeFirst()
            
            result.append(targetEntity)
        }
        return result
    }
    
    private func getRightHandTargetTransform() async -> [Transform] {
        guard let greenTargetEntity = try? await Entity(named: "Hand/target_new_green", in: realityKitContentBundle) else { return [Transform()] }
        
        let originalTransform = greenTargetEntity.transform
        
        var transform_1 = originalTransform
        transform_1.translation = .init(x: -0.7, y: startingHeight - 0.2, z: -0.5)
        transform_1.rotation = getRotationCalculator(transform_1.rotation, rotationX: 1/7 * .pi, rotationY: -1/3 * .pi, rotationZ: 0)
        transform_1.scale = transform_1.scale * 0.8
        
        var transform_2  = originalTransform
        transform_2.translation = .init(x: -0.6, y: startingHeight + 0.4, z: -1.0)
        transform_2.rotation = getRotationCalculator(transform_2.rotation, rotationX: 1/6 * .pi, rotationY: -1/6 * .pi, rotationZ: 0)
        
        var transform_3  = originalTransform
        transform_3.translation = .init(x: 0.6, y: startingHeight + 0.3 , z: -0.7)
        transform_3.rotation = getRotationCalculator(transform_3.rotation, rotationX: 1/6 * .pi, rotationY: 1/6 * .pi, rotationZ: 1/3 * .pi)
        
        
        return [transform_1, transform_2, transform_3]
    }
    
    private func getLeftHandTargetTransform() async -> [Transform] {
        guard let greenTargetEntity = try? await Entity(named: "Hand/target_new_blue", in: realityKitContentBundle) else { return [Transform()] }
        
        let originalTransform = greenTargetEntity.transform
        
        var transform_1 = originalTransform
        transform_1.translation = .init(x: -0.2, y: startingHeight + 0.2, z: -1.0)
        transform_1.rotation = getRotationCalculator(transform_1.rotation, rotationX: 1/6 * .pi, rotationY: 0, rotationZ: 0)
        transform_1.scale = transform_1.scale * 0.9
        
        var transform_2  = originalTransform
        transform_2.translation = .init(x: 0.2, y: startingHeight + 0.2, z: -1.0)
        transform_2.rotation = getRotationCalculator(transform_2.rotation, rotationX: 1/6 * .pi, rotationY: 1/6 * .pi, rotationZ: 0)
        transform_1.scale = transform_1.scale * 0.8
        
        var transform_3  = originalTransform
        transform_3.translation = .init(x: 0.7, y: startingHeight - 0.2, z: -0.6)
        transform_3.rotation = getRotationCalculator(transform_3.rotation, rotationX: -1/6 * .pi, rotationY: 1/6 * .pi, rotationZ: 1/3 * .pi)
        transform_3.scale = transform_3.scale * 1.2
        
        
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
    
    func getDifferentRingColor(_ ringEntity : Entity, intChangeTo: Int32) {
        guard let modelEntity = ringEntity.findEntity(named: "Torus") else {return }

        guard var modelComponent = modelEntity.components[ModelComponent.self],
              var shaderGraphMaterial = modelComponent.materials.first as? ShaderGraphMaterial
        else { return  }

        do {
            try shaderGraphMaterial.setParameter(name: "RingColor", value: .int(intChangeTo) )
            modelComponent.materials = [shaderGraphMaterial]
            modelEntity.components.set(modelComponent)
        } catch {}
    }
    
    func addAttachmentView(_ content: RealityViewContent, _ attachments: RealityViewAttachments) {
        guard let stretchingAttachmentView = attachments.entity(for: stretchingAttachmentViewID) else {
            dump("StretchingAttachmentView not found in attachments!")
            return
        }
        stretchingAttachmentView.position = .init(x: 0, y: startingHeight + 0.4, z: -1.2)
        content.add(stretchingAttachmentView)
    }
}
