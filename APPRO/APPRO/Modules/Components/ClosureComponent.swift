//
//  ClosureComponent.swift
//  APPRO
//
//  Created by 정상윤 on 11/11/24.
//

import RealityKit
import QuartzCore

struct ClosureComponent: Component {
    
    let closure: (TimeInterval) -> Void
    
    init(closure: @escaping (TimeInterval) -> Void) {
        self.closure = closure
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
