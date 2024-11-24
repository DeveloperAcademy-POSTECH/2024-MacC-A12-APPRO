//
//  ShapeResource+.swift
//  APPRO
//
//  Created by 정상윤 on 11/21/24.
//

import RealityKit

extension ShapeResource {
    
    static func generateShapeResource(mesh: MeshResource, isConvex: Bool) async throws -> ShapeResource {
        isConvex
        ? try await ShapeResource.generateConvex(from: mesh)
        : try await ShapeResource.generateStaticMesh(from: mesh)
    }
    
}
