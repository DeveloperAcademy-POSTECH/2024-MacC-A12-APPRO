//
//  HandRollingTutorialViewModel.swift
//  APPRO
//
//  Created by marty.academy on 11/7/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

@Observable
@MainActor
final class HandRollingTutorialViewModel {
    
    let session = ARKitSession()
    var handTracking = HandTrackingProvider()
    
    var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    
    var isStartingObjectVisible = true
    var startObject = Entity()
    
    var isRightHandInFist = false
    
    let tutorialAttachmentViewID = "TutorialAttachmentView"
    
    //StretchingCounter
    var doneCount = 0
    
    //RealityViewContent
    var rightEntities: [Entity] = []
    var rightTargetEntity : Entity = Entity()
    
    var rightGuideRing = Entity()
    var rightGuideSphere = ModelEntity()
    
    let radius: Float = 0.1
    
    var rightRotationForLaunchNumber : Int = 0
    var rightRotationCount: Int = 0
    var rightRotationCollisionArray = [ false, false, false, false]
    
    var rightLaunchState = false
    
    var fistReaderRight: [Bool] = []
    
    var rightHitCount = 0
    
    
    // Tutorial Related
    var isFistMakingTutorialDone = false
    var showTarget = false
    
    func makeFirstEntitySetting (_ content: RealityViewContent) async {
        rightGuideRing = await generateGuideRing(chirality: .right)
        rightGuideSphere = generateGuideSphere(chirality: .right)
        
        rightTargetEntity = await bringTargetEntity( chirality: .right)
    }
    
    func addEntity(_ content: RealityViewContent) {
        for entity in rightEntities {
            content.add(entity)
        }
        
        if !isStartingObjectVisible {
            content.add(rightTargetEntity)
        }
        
        if showTarget {
            content.add(rightTargetEntity)
        }
    }
    
    func generateStartingObject(_ content: RealityViewContent) async {
        guard let entity = try? await Entity(named: "Hand/main_obj_applied", in: realityKitContentBundle) else { return }
        entity.name = "StartingObject"
        
        startObject = entity
        startObject.transform.translation = .init(x: 0, y: 1.4, z: -1.0)
        
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
        
        return guideRingEntity
    }
    
    func generateGuideSphere(chirality : Chirality)-> ModelEntity  {
        let guideSphereEntity = ModelEntity(mesh: .generateSphere(radius: 0.015), materials: [SimpleMaterial(color: .red, roughness: 0.0, isMetallic: false)]) // var to let
        guideSphereEntity.name = chirality == .right ? "GuideSphere_Right" : "GuideSphere_Left"
        guideSphereEntity.generateCollisionShapes(recursive: false)
        
        return guideSphereEntity
    }
    
    func bringTargetEntity (chirality: Chirality) async -> Entity {
        guard let targetEntity = try? await Entity(named: "Hand/target_new_green", in: realityKitContentBundle) else { return Entity() }
        
        var transform = targetEntity.transform
        transform.translation = .init(x: -0.6, y: 1.6, z: -1)
        transform.rotation = getRotationCalculator(transform.rotation, rotationX: 1/7 * .pi, rotationY: -1/3 * .pi, rotationZ: 0)
        transform.scale = transform.scale * 0.8
        
        let entityName = chirality == .left ? "BlueTarget_left" :"GreenTarget_right"
        
        targetEntity.name = entityName
        targetEntity.transform = transform
        
        return targetEntity
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
    
    func addAttachmentView(_ content: RealityViewContent, _ attachments: RealityViewAttachments) {
        guard let tutorialAttachmentView = attachments.entity(for: tutorialAttachmentViewID) else {
            dump("TutorialAttachmentView not found in attachments!")
            return
        }
        tutorialAttachmentView.position = .init(x: 0, y: 2.0, z: -1.2) // TODO: 추후수정
        content.add(tutorialAttachmentView)
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
}
