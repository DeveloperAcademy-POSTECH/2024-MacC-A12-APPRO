//
//  EyeStretchingError.swift
//  APPRO
//
//  Created by 정상윤 on 11/21/24.
//

import Foundation

enum EyeStretchingError: LocalizedError {
    
    case sceneNotFound
    case entityNotFound(name: String)
    case shaderGraphMaterialNotFound
    case modelComponentNotFound
    case availabeAnimationNotFound
    
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
        }
    }
    
}
