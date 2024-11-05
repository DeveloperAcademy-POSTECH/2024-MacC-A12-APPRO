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
    
    private(set) var steps: [TutorialStep] = [.init(instruction: "default", isCompleted: { true })]
    private var currentStepIndex = 0
    private var userDefulatsKey: String {
        "\(stretchingPart)TutorialSkipped"
    }
    var isNextEnabled: Bool = false
    
    init(stretching: StretchingPart) {
        self.stretchingPart = stretching
    }
    
    var isSkipped: Bool {
        UserDefaults.standard.bool(forKey: userDefulatsKey)
    }
    
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
        isNextEnabled = false
    }
    
    func skip() {
        UserDefaults.standard.setValue(true, forKey: userDefulatsKey)
        currentStepIndex = steps.count
    }
}

extension TutorialManager {
    
    static let sampleTutorialManager: TutorialManager = {
        let manager = TutorialManager(stretching: .eyes)
        
        manager.initializeSteps([
            .init(instruction: "This is step 1", isCompleted: { true }),
            .init(instruction: "This is step 2", isCompleted: { true }),
            .init(instruction: "This is step 3", isCompleted: { true })
        ])
        
        return manager
    }()
    
}
