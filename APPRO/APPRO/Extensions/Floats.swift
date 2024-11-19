//
//  Floats.swift
//  APPRO
//
//  Created by 정상윤 on 11/7/24.
//

import Foundation
import simd

typealias Float3 = SIMD3<Float>
typealias Float4 = SIMD4<Float>
typealias Float4x4 = simd_float4x4

extension Float3 {
    
    init(_ float4: Float4) {
        self.init()
        
        x = float4.x
        y = float4.y
        z = float4.z
    }
    
    func length() -> Float {
        sqrt(x * x + y * y + z * z)
    }
    
    func normalize() -> Self {
        self * 1 / length()
    }
    
}

extension Float4 {
    
    func toFloat3() -> Float3 {
        Float3(self)
    }
    
}

extension Float4x4 {
    
    func translation() -> Float3 {
        columns.3.toFloat3()
    }
    
    func forward() -> Float3 {
        columns.2.toFloat3().normalize()
    }
    
    func forwardAndUpward() -> Float3 {
        var temp = columns.2.toFloat3()
        temp.y += 0.5
        return temp.normalize()
    }
    
}
