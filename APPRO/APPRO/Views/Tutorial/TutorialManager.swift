//
//  TutorialManager.swift
//  APPRO
//
//  Created by 정상윤 on 10/31/24.
//

import Foundation
import AVFAudio

@Observable
class TutorialManager {
    
    let stretchingPart: StretchingPart
    
    private var steps: [TutorialStep]
    private(set) var currentStepIndex = 0
    
    static var audioPlayer: AVAudioPlayer?
    
    init(stretching: StretchingPart) {
        self.stretchingPart = stretching
        self.steps = stretching.tutorialInstructions.enumerated().map {
            .init(instruction: $1.instruction, audioFilename: "\(stretching)_\($0 + 1)", isNextButtonRequired: $1.isNextButtonRequired )
        }
    }
    
    var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }
    
    var currentStep: TutorialStep? {
        steps[safe: currentStepIndex]
    }
    
    func completeCurrentStep() {
        guard var currentStep else { return }
        steps[currentStepIndex].isCompleted = true
    }
    
    func advanceToNextStep() {
        currentStepIndex += 1
    }
    
    func skip() {
        UserDefaults.standard.setValue(true, forKey: "\(stretchingPart)TutorialSkipped")
        currentStepIndex = steps.count
    }
    
    func playInstructionAudio() {
        if let path = Bundle.main.path(forResource: currentStep?.audioFilename, ofType: "mp3"){
            do{
                TutorialManager.audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                TutorialManager.audioPlayer?.prepareToPlay()
                TutorialManager.audioPlayer?.play()
                
            }catch {
                print("Error on Playing Instruction Audio : \(error)")
            }
        }
    }
    
    func stopInstructionAudio() {
        TutorialManager.audioPlayer?.stop()
    }
}

extension TutorialManager {
    
    static func isSkipped(part: StretchingPart) -> Bool {
        UserDefaults.standard.bool(forKey: "\(part)TutorialSkipped")
    }
    
}

private extension Array where Element == TutorialStep {
    
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
}
