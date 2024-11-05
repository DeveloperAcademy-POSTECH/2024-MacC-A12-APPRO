//
//  TutorialManager.swift
//  APPRO
//
//  Created by 정상윤 on 10/31/24.
//

import Foundation

@MainActor
@Observable
class TutorialManager {
    
    let stretchingPart: StretchingPart
    
    private let steps: [TutorialStep]
    private var currentStepIndex = 0
    private var userDefulatsKey: String {
        "\(stretchingPart)TutorialSkipped"
    }
    
    init(stretching: StretchingPart, steps: [TutorialStep]) {
        self.stretchingPart = stretching
        self.steps = steps
    }
    
    var isSkipped: Bool {
        UserDefaults.standard.bool(forKey: userDefulatsKey)
    }
    
    var currentStep: TutorialStep? {
        steps[safe: currentStepIndex]
    }
    
    func advanceToNextStep() {
        currentStepIndex += 1
    }
    
    func skip() {
        UserDefaults.standard.setValue(true, forKey: userDefulatsKey)
        currentStepIndex = steps.count
    }
    
}

private extension Array where Element == TutorialStep {
    
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
}
