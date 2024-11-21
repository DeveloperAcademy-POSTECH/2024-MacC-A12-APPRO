//
//  TapGestureComponent.swift
//  APPRO
//
//  Created by 정상윤 on 11/21/24.
//

import RealityKit

struct TapGestureComponent: Component {
    
    let onEnded: () -> Void
    
    init(onEnded: @escaping () -> Void) {
        self.onEnded = onEnded
    }
    
}
