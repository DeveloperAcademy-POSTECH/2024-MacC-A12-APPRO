//
//  ClosureComponent.swift
//  PracticeVisionOS
//
//  Created by 정상윤 on 10/18/24.
//

import Foundation
import RealityKit

struct ClosureComponent: Component {
    
    let closure: (TimeInterval) -> Void
    
    init(closure: @escaping (TimeInterval) -> Void) {
        self.closure = closure
        
        ClosureSystem.registerSystem()
    }
    
}

struct ClosureSystem: System {
    
    static let query = EntityQuery(where: .has(ClosureComponent.self))
    
    init(scene: Scene) {}
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let component = entity.components[ClosureComponent.self] else { return }
            
            component.closure(context.deltaTime)
        }
    }
    
}
