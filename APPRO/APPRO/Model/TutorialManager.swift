//
//  TutorialManager.swift
//  APPRO
//
//  Created by 정상윤 on 10/31/24.
//

class TutorialManager {
    
    private(set) var steps: [TutorialStep] = []
    private var currentStepIndex = 0
    
    var isCompleted: Bool {
        currentStepIndex >= steps.count
    }
    
    var currentStep: TutorialStep {
        steps[currentStepIndex]
    }
    
    func initializeSteps(_ steps: [TutorialStep]) {
        self.steps = steps
    }
    
    func advanceToNextStep() {
        currentStepIndex += 1
    }
    
    func skip() {
        currentStepIndex = steps.count
    }
    
}
