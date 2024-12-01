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
    
    func animateCoinColorWhenWrongHit( targetEntity: Entity ) {
        guard let model = targetEntity.components[ModelComponent.self], let material = model.materials.first as? PhysicallyBasedMaterial else {
            print("No material Found on coin Entity: \(targetEntity)")
            return
        }
        
        var redBaseColor = material.baseColor
        redBaseColor.tint = .red
        
        let modelInRed = controlModelMaterial(model: model, material: material, color: redBaseColor)
        targetEntity.components.set(modelInRed)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1 ) {
            targetEntity.components.set(model)
        }
    }
    
    func controlModelMaterial(model: ModelComponent, material: PhysicallyBasedMaterial, color: PhysicallyBasedMaterial.BaseColor) -> ModelComponent {
        var materialForModification = material
        var modelForModification = model
        materialForModification.baseColor = color
        modelForModification.materials = [materialForModification]
        
        return modelForModification
    }
    
    func playCustomAudioWith5Sec(timerEntity : Entity) {
        let taskManager = TaskManager()
        
        for index in 0..<5 {
            let task = Task {
                try? await Task.sleep(nanoseconds: UInt64(index) * 900_000_000)
                if Task.isCancelled { return }
                
                if timerFiveProgressChecker[index] {
                    soundHelper.playSound(.neckTimer, on: timerEntity)

                    if index == 4 {
                        await taskManager.cancelAllTasks()
                    }
                } else {
                    await taskManager.cancelAllTasks()
                    return
                }
            }
            Task { await taskManager.addTask(task) }
        }
    }
    
    func stopAllTimerProgress() {
        timerFiveProgressChecker = timerFiveProgressChecker.map({ _ in false})
    }
    
    func initiateAllTimerProgress() {
        timerFiveProgressChecker = timerFiveProgressChecker.map({ _ in true})
    }
    
}
