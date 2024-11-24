//
//  NeckTutorialViewModel.swift
//  APPRO
//
//  Created by marty.academy on 11/21/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

extension NeckTutorialViewModel {
    
    func getTwoAxisForChangeablePoints(transform: float4x4, isVertical: Bool) -> [Float3] {
        let localXAxis = transform.columns.0.toFloat3().normalize()
        let localYAxis = transform.columns.1.toFloat3().normalize()
        let localZAxis = transform.columns.2.toFloat3().normalize()
        
        if isVertical {
            return [
                localYAxis,
                localZAxis
            ]
        } else {
            return [
                localXAxis,
                localZAxis
            ]
        }
    }
    
    func drawSemiCirclePoints(transform: float4x4, isVertical: Bool, steps: Int) -> [Float3] {
        guard steps > 1 else { return [] }
        
        let radius = ( startingHeight / 10 ) * 10
        let center = transform.translation()
        
        let requiredAxis = getTwoAxisForChangeablePoints(transform: transform, isVertical: isVertical)
        
        let startingAxis = requiredAxis[0]
        let crossAxis = requiredAxis[1]

        var points: [Float3] = []

        for i in 0...steps {
            let angle = Float.pi * Float(i) / Float(steps)
            
            let offset = radius * cos(angle) * startingAxis - radius * sin(angle) * crossAxis
            let point = center + offset
            points.append(point)
        }

        return points
    }
}

private extension Float {
    static let zDistanceToPig = Float(2.0)
}
