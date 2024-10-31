//
//  SIMD4+.swift
//  APPRO
//
//  Created by Damin on 10/31/24.
//

import Foundation

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}
