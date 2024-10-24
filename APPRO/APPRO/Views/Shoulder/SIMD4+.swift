//
//  SIMD4+.swift
//  ParabolaTest
//
//  Created by Damin on 10/15/24.
//

import Foundation

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}
