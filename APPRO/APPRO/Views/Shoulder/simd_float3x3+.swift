//
//  simd_float3x3+.swift
//  ParabolaTest
//
//  Created by Damin on 10/15/24.
//

import simd

// 회전 행렬 계산을 위한 확장 함수
extension simd_float3x3 {
    init(rotationAngle angle: Float, axis: simd_float3) {
        let normalizedAxis = simd_normalize(axis)
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        let oneMinusCos = 1 - cosAngle
        let x = normalizedAxis.x, y = normalizedAxis.y, z = normalizedAxis.z
        
        self.init(
            simd_float3(cosAngle + oneMinusCos * x * x,
                        oneMinusCos * x * y - sinAngle * z,
                        oneMinusCos * x * z + sinAngle * y),
            
            simd_float3(oneMinusCos * y * x + sinAngle * z,
                        cosAngle + oneMinusCos * y * y,
                        oneMinusCos * y * z - sinAngle * x),
            
            simd_float3(oneMinusCos * z * x - sinAngle * y,
                        oneMinusCos * z * y + sinAngle * x,
                        cosAngle + oneMinusCos * z * z)
        )
    }
}
