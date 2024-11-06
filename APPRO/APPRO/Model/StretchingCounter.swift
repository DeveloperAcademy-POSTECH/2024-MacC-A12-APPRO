//
//  StretchingCounter.swift
//  APPRO
//
//  Created by 정상윤 on 11/6/24.
//

import Foundation

@MainActor
protocol StretchingCounter: AnyObject {
    var doneCount: Int { get }
    var maxCount: Int { get }
}
