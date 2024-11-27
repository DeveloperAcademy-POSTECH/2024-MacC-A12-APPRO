//
//  RingCollisionState.swift
//  APPRO
//
//  Created by 정상윤 on 11/27/24.
//

import Foundation

struct EyeRingCollisionState {
    
    let restrictLineCollided: Bool
    let innerPlaneCollided: Bool
    
    var eyesAreInside: Bool {
        innerPlaneCollided && !restrictLineCollided
    }
    
    func replacing(restrictLine: Bool) -> Self {
        .init(
            restrictLineCollided: restrictLine,
            innerPlaneCollided: innerPlaneCollided
        )
    }
    
    func replacing(innerPlane: Bool) -> Self {
        .init(
            restrictLineCollided: restrictLineCollided,
            innerPlaneCollided: innerPlane
        )
    }
    
}
