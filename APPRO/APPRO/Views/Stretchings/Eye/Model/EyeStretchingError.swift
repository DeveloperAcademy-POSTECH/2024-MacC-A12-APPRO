//
//  EyeStretchingError.swift
//  APPRO
//
//  Created by 정상윤 on 11/21/24.
//

import Foundation

enum EyeStretchingError: LocalizedError {
    
    case entityNotFound(name: String)
    case shaderGraphMaterialNotFound
    case modelComponentNotFound
    
    var errorDescription: String {
        switch self {
        case .entityNotFound(let name):
            "Entity named '\(name)' not found"
        case .shaderGraphMaterialNotFound:
            "Shader Graph Material is not found"
        case .modelComponentNotFound:
            "Model Component is not found"
        }
    }
    
}
