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
    
    func playSpatialAudio(_ entity: Entity, audioInfo: AudioFindHelper) async {
        let audioInfoDetail = audioInfo.detail
        await findAudioResourceAndPlay(entity, spatialAudioName: audioInfoDetail.spatialAudioName, resourceLocation: audioInfoDetail.resourceLocation, resourceFrom: audioInfoDetail.resourceFrom)
    }
    
    func findAudioResourceAndPlay(_ entity: Entity, spatialAudioName: String, resourceLocation: String, resourceFrom: String) async {
        guard let audioEntity = entity.findEntity(named: spatialAudioName),
              let resource = try? await AudioFileResource(named: resourceLocation,
                                                          from: resourceFrom,
                                                          in: realityKitContentBundle) else {
            print("No Audio Resource Found:  \(resourceLocation) / \(resourceFrom)")
            return }
        
        let audioPlayer = audioEntity.prepareAudio(resource)
        audioPlayer.play()
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
}
