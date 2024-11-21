//
//  GestureComponent.swift
//  APPRO
//
//  Created by 정상윤 on 11/22/24.
//

import RealityKit

struct TapGestureComponent: Component {
    
    let onEnded: () -> Void
    
}


struct LongPressGestureComponent: Component {
    
    let onEnded: () -> Void
    
}
