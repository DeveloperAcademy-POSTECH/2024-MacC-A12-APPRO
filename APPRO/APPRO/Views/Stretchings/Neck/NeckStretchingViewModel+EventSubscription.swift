//
//  NeckTutorialViewModel.swift
//  APPRO
//
//  Created by marty.academy on 11/21/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

extension NeckStretchingViewModel {
    
    private func getCoinIndex (_ string: String) -> Int? {
        let coinStringCount = "coin_".count
        return Int(string.dropFirst(coinStringCount))
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
            
            Task {
                if entityA.name == "______" && entityB.name == "Boole" { // ModelEntity Name : ______ for pig, Boole for coin
                    guard let coinEntity = entityB.parent?.parent?.parent?.parent else { return }
                    guard let index: Int = self.getCoinIndex(coinEntity.name) else { return }
                    
                    if self.manageCollisionBound(collidedIndex: index) {
                        await self.playSpatialAudio(coinEntity, audioInfo: .coinCollisionInRightOrder)
                        self.setOpacityZero(entity: entityB)
                        
                        DispatchQueue.main.async {
                            coinEntity.isEnabled = false
                        }
                    } else {
                        self.animateCoinColorWhenWrongHit(targetEntity: entityB)
                        await self.playSpatialAudio(coinEntity, audioInfo: .coinCollisionInWrongOrder)
                    }
                }
            }
            
            if entityA.name == "______" && entityB.name == "TimerRing" {
                let parentEntity = entityB.parent?.parent
                self.playPredefinedAnimation(animationEntity: parentEntity!)
            }
        }
        
        _ = content.subscribe(to: CollisionEvents.Ended.self, on: nil ) { event in
            let entityA = event.entityA
            let entityB = event.entityB
            
            if entityA.name == "______" && entityB.name == "TimerRing" {
                self.timerController?.stop()
            }
        }
        
        _ = content.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: nil) { event in
            guard let entity = event.playbackController.entity else { return }
            
            if entity.name.contains(/timer_\d+/) {
                if self.completionStatusArray[0] {
                    self.completionStatusArray[1] = true
                } else {
                    self.completionStatusArray[0] = true
                }
            }
            
            DispatchQueue.main.async {
                entity.isEnabled = false
            }
        }
    }
}

private extension Float {
    static let zDistanceToPig = Float(2.0)
}
