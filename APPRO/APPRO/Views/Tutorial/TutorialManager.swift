//
//  TutorialManager.swift
//  APPRO
//
//  Created by 정상윤 on 10/31/24.
//

import Foundation
import AVFAudio

@Observable
@MainActor
class TutorialManager {
    
    let stretchingPart: StretchingPart
    
    private var steps: [TutorialStep]
    private(set) var currentStepIndex = 0
    
    static var audioPlayer: AVAudioPlayer?
    
    init(stretching: StretchingPart) {
        self.stretchingPart = stretching
        self.steps = stretching.tutorialInstructions.map { .init(instruction: $0) }
    }
    
    var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }
    
    var currentStep: TutorialStep? {
        steps[safe: currentStepIndex]
    }
    
    func completeCurrentStep() {
        guard steps.indices.contains(currentStepIndex) else { return }
        
        steps[currentStepIndex].isCompleted = true
    }
    
    func advanceToNextStep() {
        currentStepIndex += 1
    }
    
    func skip() {
        UserDefaults.standard.setValue(true, forKey: "\(stretchingPart)TutorialSkipped")
        currentStepIndex = steps.count
    }
    
    func playInstructionAudio(_ audioFile: String) {
        if let path = Bundle.main.path(forResource: audioFile, ofType: "mp3"){
               do{
                   TutorialManager.audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                   TutorialManager.audioPlayer?.prepareToPlay()
                   TutorialManager.audioPlayer?.play()

               }catch {
                   print("Error on Playing Instruction Audio : \(error)")
               }
           }
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
