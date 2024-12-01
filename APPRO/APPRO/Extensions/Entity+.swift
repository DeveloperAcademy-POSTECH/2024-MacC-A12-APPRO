//
//  Entity+.swift
//  APPRO
//
//  Created by 정상윤 on 11/21/24.
//

import Foundation
import RealityKit

extension Entity {
    
    func generateMeshResource(modelEntityName: String) throws -> MeshResource {
        guard let modelEntity = self.findEntity(named: modelEntityName) as? ModelEntity else {
            throw EntityError.entityNotFound(name: modelEntityName)
        }
        
        guard let mesh = modelEntity.model?.mesh else {
            throw EntityError.modelComponentNotFound
        }
        
        return mesh
    }
    
    @discardableResult
    func playOpacityAnimation(
        from: Float,
        to: Float,
        duration: TimeInterval = 1.0
    ) throws -> AnimationPlaybackController {
        let animationDefinition = FromToByAnimation(
            from: from,
            to: to,
            bindTarget: .opacity
        )
        let animationResource = try AnimationResource.generate(with: animationDefinition)
        
        return self.playAnimation(animationResource, transitionDuration: duration)
    }
    
    @discardableResult
    func playAudio(
        filename: String,
        configuration: AudioFileResource.Configuration = .init()
    ) async throws -> AudioPlaybackController {
        guard let path = Bundle.main.path(forResource: filename, ofType: "mp3") else {
            throw EntityError.audioFileNotFoundInBundle(filename: filename)
        }
        
        let audioResource = try await AudioFileResource(
            contentsOf: URL(filePath: path),
            configuration: configuration
        )
        return playAudio(audioResource)
    }
    
}

enum EntityError: LocalizedError {
    
    case sceneNotFound
    case entityNotFound(name: String)
    case shaderGraphMaterialNotFound
    case modelComponentNotFound
    case availabeAnimationNotFound
    case audioFileNotFoundInBundle(filename: String)
    case componentNotFound(any Component.Type)
    
    var errorDescription: String {
        switch self {
        case .sceneNotFound:
            "Entity is not stored by any scene"
        case .entityNotFound(let name):
            "Entity named '\(name)' not found"
        case .shaderGraphMaterialNotFound:
            "Shader Graph Material is not found"
        case .modelComponentNotFound:
            "Model Component is not found"
        case .availabeAnimationNotFound:
            "No available animation found"
        case .audioFileNotFoundInBundle(let filename):
            "Audio file named \(filename) is not found"
        case .componentNotFound(let componentType):
            "Entity component not found: \(componentType)"
        }
    }
    
}

protocol HasChildren {
    associatedtype ChildrenEntity: RawRepresentable<String>
}

extension HasChildren where Self: Entity {
    
    func getChild(_ child: ChildrenEntity) throws -> Entity {
        guard let childEntity = findEntity(named: child.rawValue) else {
            throw EntityError.entityNotFound(name: child.rawValue)
        }
        return childEntity
    }
    
}
