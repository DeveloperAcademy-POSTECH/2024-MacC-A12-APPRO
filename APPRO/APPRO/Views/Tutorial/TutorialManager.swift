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
class TutorialManager: NSObject, AVAudioPlayerDelegate {
    
    let stretchingPart: StretchingPart
    
    private var steps: [TutorialStep]
    private(set) var currentStepIndex = 0
    private var isCurrentInstructionCompleted: Bool = false
    static var audioPlayer: AVAudioPlayer?
    var onAudioFinished: (() -> Void)? // 오디오 재생 완료 후 호출할 콜백
    
    init(stretching: StretchingPart) {
        self.stretchingPart = stretching
        self.steps = stretching.tutorialInstructions.enumerated().map {
            .init(instruction: $1, audioFilename: "\(stretching)_\($0 + 1)", isNextButtonRequired: TutorialManager.getNextButtonRequiredInfo(tutorialStretching: stretching)[$0]) }
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
    
    func playInstructionAudio() {
        if let path = Bundle.main.path(forResource: currentStep?.audioFilename, ofType: "mp3"){
               do{
                   TutorialManager.audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                   TutorialManager.audioPlayer?.delegate = self
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
    
    // 오디오 재생 완료 감지
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            Task { @MainActor in
                onAudioFinished?() // 오디오 종료 시 콜백 호출
                onAudioFinished = nil // 콜백 초기화
            }
        }
    }
}

extension TutorialManager {
    
    static func isSkipped(part: StretchingPart) -> Bool {
        UserDefaults.standard.bool(forKey: "\(part)TutorialSkipped")
    }
    
}

extension TutorialManager {

    static func getNextButtonRequiredInfo(tutorialStretching: StretchingPart) -> [Bool] {
        switch tutorialStretching {
        case .eyes:
            [false, true, false, true]
        case .wrist:
            [false, true, false, false, true]
        case .shoulder:
            [false, true, false, false, false, true]
        }
    }
    
}

private extension Array where Element == TutorialStep {
    
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
}
