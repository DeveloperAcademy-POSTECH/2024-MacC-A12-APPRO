//
//  NeckTutorialViewModel.swift
//  APPRO
//
//  Created by marty.academy on 11/21/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

extension NeckTutorialViewModel {
    
    private func getCoinIndex (_ string: String) -> Int? {
        let regex = try! NSRegularExpression(pattern: "(?<=coin_)\\d+", options: [])
        if let match = regex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count)) {
            if let range = Range(match.range, in: string) {
                let result = Int(string[range])
                return result
            }
        }
        return nil
    }
    
    func manageCollisionBound(collidedIndex: Int) -> Bool {
        if collidedIndex == collisionBound.lowerBoundIndex { // [lowerBound, upperBound] = [5,7] 에서 5 충돌시 => [4, 7] 로 변경
            let nextLowerBoundIndex = collisionBound.lowerBoundIndex - 1
            
            if nextLowerBoundIndex >= 0 {
                collisionBound.lowerBoundIndex = nextLowerBoundIndex
            }
            
            return true
        } else if collidedIndex == collisionBound.upperBoundIndex { // [lowerBound, upperBound] = [5,7] 에서 7 충돌시 => [5, 8] 로 변경
            let nextUpperBoundIndex = collisionBound.upperBoundIndex + 1
            
            if nextUpperBoundIndex <= guidingEntitiesCount - 1 {
                collisionBound.upperBoundIndex = nextUpperBoundIndex
            }
            
            return true
        } else if collisionBound.lowerBoundIndex == 0 && collisionBound.upperBoundIndex == 0 { // 첫 충돌시 6 충돌 -> [lowerBound, upperBound] = [5,7]
            collisionBound.lowerBoundIndex = collidedIndex - 1
            collisionBound.upperBoundIndex = collidedIndex + 1
            return true
        }
        
        return false
    }
    
    func setOpacityZero(entity: Entity) {
        entity.components.set(OpacityComponent(opacity: 0))
    }
    
    func subscribePigCollisionEvent(_ content: RealityViewContent) {
        _ = content.subscribe(to: CollisionEvents.Began.self, on: nil ) { event in
            
            let entityA = event.entityA
            let entityB = event.entityB
            
            if entityA.name == "______" && entityB.name == "Boole" { // ModelEntity Name : ______ for pig, Boole for coin
                guard let coinEntity = entityB.parent?.parent?.parent?.parent else { return }
                guard let index: Int = self.getCoinIndex(coinEntity.name) else { return }
                
                if self.manageCollisionBound(collidedIndex: index) {
                    self.setOpacityZero(entity: entityB)
                }
            }
            
            if entityA.name == "______" && entityB.name == "TimerRing" {
                let parentEntity = entityB.parent?.parent

            }
        }
        
        _ = content.subscribe(to: CollisionEvents.Ended.self, on: nil ) { event in
            let entityA = event.entityA
            let entityB = event.entityB
            
            if entityA.name == "______" && entityB.name == "TimerRing" {
                self.timerController?.stop()
            }
        }
        //AnimationEvents.PlaybackCompleted.self
        _ = content.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: nil) { event in
            
        }
    }

}

private extension Float {
    static let zDistanceToPig = Float(2.0)
}
