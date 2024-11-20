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
    var isAudioFinished: Bool = false
    
    init(stretching: StretchingPart) {
        self.stretchingPart = stretching
        self.steps = stretching.tutorialInstructions.enumerated().map {
            .init(instruction: $1, audioFilename: "\(stretching)_\($0 + 1)" )
        }
    }
    
    var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }
    
    var currentStep: TutorialStep? {
        steps[safe: currentStepIndex]
    }
    
    /// 행동 조건 완료시 실행
    func advanceToNextStep() {
        // 마지막 단계 일때는 스킵
        guard !isLastStep else { return }
        /// 재생 후
        if isAudioFinished {
            currentStepIndex += 1
            isAudioFinished = false
        } else {
            /// 재생 전, 중
            onAudioFinished = {
                self.currentStepIndex += 1
                self.isAudioFinished = false
            }
        }
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
               } catch {
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
                onAudioFinished?() // 오디오 종료시 콜백 호출
                onAudioFinished = nil // 콜백 초기화
                isAudioFinished = true
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
