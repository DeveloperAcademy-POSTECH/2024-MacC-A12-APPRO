//
//  HandRollingStretchingViewModel+CollisionHandling.swift
//  APPRO
//
//  Created by marty.academy on 10/31/24.
//

import SwiftUI
import ARKit
import RealityKit
import RealityKitContent

extension HandRollingStretchingViewModel {
    
    func bringCollisionHandler(_ content: RealityViewContent) {
        _ = content.subscribe(to: CollisionEvents.Began.self, on: nil) { collisionEvent in
            
            let entityA = collisionEvent.entityA
            let entityB = collisionEvent.entityB
            
            // rotation recognition handling : right
            let regex = /ring_collide\d/
            
            if entityA.name == "GuideSphere_Right" && entityB.name.contains(regex)  {
                let index: Int = Int(String(entityB.name.last!)) ?? 0
                self.rightRotationCollisionArray[index] = true
            } else if entityB.name == "GuideSphere_Right" && entityA.name.contains(regex) {
                let index: Int = Int(String(entityA.name.last!)) ?? 0
                self.rightRotationCollisionArray[index] = true
            }
            
            if self.rightRotationCollisionArray.filter({ $0 == false }).isEmpty {
                self.rightRotationCount += 1
                for index in 0..<self.rightRotationCollisionArray.count {
                    self.rightRotationCollisionArray[index] = false
                }
                
            }
            
            // rotation recognition handling : left
            if entityA.name == "GuideSphere_Left" && entityB.name.contains(regex)  {
                let index: Int = Int(String(entityB.name.last!)) ?? 0
                self.leftRotationCollisionArray[index] = true
            } else if entityB.name == "GuideSphere_Left" && entityA.name.contains(regex) {
                let index: Int = Int(String(entityA.name.last!)) ?? 0
                self.leftRotationCollisionArray[index] = true
            }
            
            if self.leftRotationCollisionArray.filter({ $0 == false }).isEmpty {
                self.leftRotationCount += 1
                for index in 0..<self.leftRotationCollisionArray.count {
                    self.leftRotationCollisionArray[index] = false
                }
            }
            
            Task {
                if entityA.name == "Spiral" && entityB.name == "Cylinder_002" {
                    await self.spiralCollisionHandler(spiral: entityA, target: entityB)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
                        entityA.removeFromParent()
                    }
                } else if entityB.name == "Spiral" && entityA.name == "Cylinder_002" {
                    await self.spiralCollisionHandler(spiral: entityB, target: entityA)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
                        entityB.removeFromParent()
                    }
                }
            }
            
        }
    }
    
    private func spiralCollisionHandler(spiral: Entity, target: Entity) async {
        guard let spiralEntity = spiral.parent?.parent?.parent?.parent else { return }
        guard let targetEntity = target.parent?.parent?.parent else { return }
        
        /*
         Target Name Pattern : ex) BlueTarget_left_1
         Spiral Name Pattern : ex) Spiral_right_1
         */
        let spiralChiralityAndScore = getStringBehindFirstUnderscore(spiralEntity.name)
        
        let targetChiralityName = getChiralityValue(targetEntity.name)
        let targetChiralityValue: Chirality = targetChiralityName == "left" ? .left : .right
        
        // 조건 : 발사체와 과녁의 chirality 가 동일하고, 발사체의 회전수가 3 이상일 것.
        if  Int(spiralChiralityAndScore.suffix(1)) ?? 0 >= 3 && spiralChiralityAndScore.contains(targetChiralityName){
            try? animateForHittingTarget(targetEntity, spiralEntity: spiralEntity)
            try? await playSpatialAudio(targetEntity, audioInfo: AudioFindHelper.handTargetHitRight(chirality: targetChiralityValue))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.removeTargetFromArrayAndContext(targetEntity: targetEntity, isLeft: spiralChiralityAndScore.starts(with: "left"), canBeCountedAsScore: true)
            }
        } else {
            getWrongTargetColorChange(target as! ModelEntity, chirality: targetChiralityValue, intChangeTo: 1)
            try? animateForHittingTarget(targetEntity, spiralEntity: spiralEntity)
            try? await playSpatialAudio(targetEntity, audioInfo: AudioFindHelper.handTargetHitWrong(chirality: targetChiralityValue))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 ) {
                self.removeTargetFromArrayAndContext(targetEntity: targetEntity, isLeft: spiralChiralityAndScore.starts(with: "left"), canBeCountedAsScore: false)
            }
        }
    }
    
    private func removeTargetFromArrayAndContext (targetEntity: Entity, isLeft: Bool, canBeCountedAsScore: Bool) {
        targetEntity.removeFromParent()
        
        if isLeft  {
            guard let index = leftTargetEntities.firstIndex(where: {$0.name == targetEntity.name} ) else { return }
            leftTargetEntities.remove(at: index)
            if canBeCountedAsScore {
                leftHitCount += 1
            }
            
        } else {
            guard let index = rightTargetEntities.firstIndex(where: {$0.name == targetEntity.name} ) else { return }
            rightTargetEntities.remove(at: index)
            if canBeCountedAsScore {
                rightHitCount += 1
            }
        }
    }
    
    
    private func getChiralityValue (_ string: String) -> String {
        let regex = try! NSRegularExpression(pattern: "(?<=_)(right|left)(?=_)", options: [])
        if let match = regex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count)) {
            if let range = Range(match.range(at: 1), in: string) {
                let result = String(string[range])
                return result
            }
        }
        return ""
    }
    
    
    private func getStringBehindFirstUnderscore (_ string: String) -> String {
        let regex = try! NSRegularExpression(pattern: "_([^_]+_[^_]+)", options: [])
        if let match = regex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count)) {
            if let range = Range(match.range(at: 1), in: string) {
                let result = String(string[range])
                return result
            }
        }
        return ""
    }
    
    private func getWrongTargetColorChange (_ targetEntity: ModelEntity, chirality: Chirality, intChangeTo: Int32) {
        guard var modelComponent = targetEntity.components[ModelComponent.self] else { return }
        
        guard let shaderGraphMaterial = modelComponent.materials as? [ShaderGraphMaterial] else { return }
        
        var materialArray: [ShaderGraphMaterial] = []
        
        for material in shaderGraphMaterial {
            do {
                var shaderMaterial = material
                try shaderMaterial.setParameter(name: "TargetColor", value: .int(intChangeTo) )
                materialArray.append(shaderMaterial)
            } catch {}
        }
        
        modelComponent.materials = materialArray
        targetEntity.components.set(modelComponent)
    }
    
    private func animateForHittingTarget(_ targetEntity: Entity, spiralEntity: Entity ) throws {
        let spiralTansformMatrix = spiralEntity.transform.matrix
        let xAxisDirection = spiralTansformMatrix.columns.0 // x axis
        let direction = simd_float3(xAxisDirection.x, xAxisDirection.y, xAxisDirection.z)
        
        let originalTransform = targetEntity.transform
        
        var newTransform = originalTransform
        newTransform.translation = targetEntity.position + 0.2 * direction
        
        let goInDirection = FromToByAnimation<Transform> (
            name: "backOffWhenHttingTarget",
            from: originalTransform,
            to: newTransform,
            duration: 0.4,
            bindTarget: .transform
        )
        
        let comeBackFromDirection = FromToByAnimation<Transform> (
            name: "comeBackWhenHttingTarget",
            from: newTransform,
            to: originalTransform,
            duration: 0.3,
            bindTarget: .transform
        )
        
        let backOffAnimation = try AnimationResource.generate(with: goInDirection)
        targetEntity.playAnimation(backOffAnimation, transitionDuration: 0.4)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            do {
                let comeBackAnimation = try AnimationResource.generate(with: comeBackFromDirection)
                targetEntity.playAnimation(comeBackAnimation, transitionDuration: 0.3)
            } catch {
                print("Failed to generate come-back animation: \(error)")
            }
        }
    }
}
