//
//  Entity+.swift
//  APPRO
//
//  Created by 정상윤 on 11/21/24.
//

import RealityKit

extension Entity {
    
    func generateMeshResource(modelEntityName: String) throws -> MeshResource {
        guard let modelEntity = self.findEntity(named: modelEntityName) as? ModelEntity else {
            throw EyeStretchingError.entityNotFound(name: modelEntityName)
        }
        
        guard let mesh = modelEntity.model?.mesh else {
            throw EyeStretchingError.modelComponentNotFound
        }
        
        return mesh
    }
    
}
