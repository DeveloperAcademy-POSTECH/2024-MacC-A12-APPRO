//
//  EyeStretchingDisturbEntity.swift
//  APPRO
//
//  Created by 정상윤 on 11/21/24.
//

import RealityKit
import RealityKitContent

final class EyeStretchingDisturbEntity: Entity {
    
    private let originalScale: Float3 = [0.17, 0.17, 0.17]
    private var largeScale: Float3 {
        originalScale * 1.5
    }
    
    required init() {
        super.init()
        
        self.transform.scale = originalScale
    }
    
    func loadCoreEntity(type: DisturbEntityType) async throws {
        let entity = try await Entity(
            named: EyeStretchingEntityType.disturbEntity(type: type).loadURL,
            in: realityKitContentBundle
        )
        
        addChild(entity)
    }
    
    func setGestureComponent(type: DisturbEntityType, component: Component) throws {
        guard let entity = findEntity(named: type.rawValue) else {
            throw EntityError.entityNotFound(name: type.rawValue)
        }
        
        entity.components.set(component)
    }
    
    func enlarge() {
        var transform = transform
        transform.scale = largeScale
        move(to: transform, relativeTo: nil, duration: 1.0)
    }
    
    func reduce() {
        var transform = transform
        transform.scale = originalScale
        move(to: transform, relativeTo: nil, duration: 0.5)
    }
    
    func restoreScale() {
        var transform = transform
        transform.scale = originalScale
        move(to: transform, relativeTo: nil, duration: 1.0)
    }
    
    func disappear() {
        var transform = transform
        transform.scale = .zero
        move(to: transform, relativeTo: nil, duration: 0.5)
    }
    
}
