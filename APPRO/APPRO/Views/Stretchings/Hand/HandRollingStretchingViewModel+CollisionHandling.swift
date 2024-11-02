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
    
    func bringCollisionHandler(_ content: RealityViewContent) -> Void {
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
            
            if entityA.name == "Spiral" && entityB.name == "Cylinder_009" {
                self.spiralCollisionHandler(spiral: entityA, target: entityB)
            } else if entityB.name == "Spiral" && entityA.name == "Cylinder_009" {
                self.spiralCollisionHandler(spiral: entityB, target: entityA)
            }
        }
    }
    
    private func spiralCollisionHandler(spiral: Entity, target: Entity) {
        guard let spiralEntity = spiral.parent?.parent?.parent?.parent else { return }
        guard let targetEntity = target.parent?.parent?.parent else { return }
        
        /*
         Target Name Pattern : ex) BlueTarget_left_1
         Spiral Name Pattern : ex) Spiral_right_1
         */
        let spiralChiralityAndScore = getStringBehindFirstUnderscore(spiralEntity.name)
        let targetChiralityAndScore = getStringBehindFirstUnderscore(targetEntity.name)
        
        if spiralChiralityAndScore == targetChiralityAndScore {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                
                spiralEntity.removeFromParent()
                targetEntity.removeFromParent()
                
                if spiralChiralityAndScore.starts(with: "left")  {
                    guard let index = self.leftTargetEntities.firstIndex(where: {$0.name == targetEntity.name} ) else { return }
                    self.leftTargetEntities.remove(at: index)
                } else {
                    guard let index = self.rightTargetEntities.firstIndex(where: {$0.name == targetEntity.name} ) else { return }
                    self.rightTargetEntities.remove(at: index)
                }
            }
        }
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
}
