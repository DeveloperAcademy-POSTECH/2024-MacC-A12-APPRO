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

    func playAppearAnimation(entity: Entity) -> AnimationPlaybackController? {
        playAnimation(
            entity: entity,
            definition: FromToByAnimation(from: Float(0.0), to: Float(1.0), bindTarget: .opacity),
            duration: 1.0
        )
    }
    
    func playDisappearAnimation(entity: Entity) -> AnimationPlaybackController? {
        playAnimation(
            entity: entity,
            definition: FromToByAnimation(from: Float(1.0), to: Float(0.0), bindTarget: .opacity),
            duration: 0.2
        )
    }
    
    func playAnimation(
        entity: Entity,
        definition: AnimationDefinition,
        duration: TimeInterval = 0
    ) -> AnimationPlaybackController? {
        do {
            let resource = try AnimationResource.generate(with: definition)
            return entity.playAnimation(resource, transitionDuration: duration)
        } catch {
            dump("playAnimation failed: \(error)")
            return nil
        }
    }
    
    func playPredefinedAnimation(animationEntity: Entity) {
        for animation in animationEntity.availableAnimations {
            let animation = animation.repeat(count: 1)
            timerController = animationEntity.playAnimation(animation, transitionDuration: 0.0, startsPaused: false)
            break
        }
    }
}
