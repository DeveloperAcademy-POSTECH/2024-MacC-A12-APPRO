//
//  TutorialStep.swift
//  APPRO
//
//  Created by 정상윤 on 10/31/24.
//

import Foundation

struct TutorialStep {
    let instruction: String
    var isCompleted: Bool = false
    let audioFilename: String
    let isNextButtonRequired: Bool
}
