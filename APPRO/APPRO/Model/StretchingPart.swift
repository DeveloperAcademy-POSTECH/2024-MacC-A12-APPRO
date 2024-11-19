//
//  Stretching.swift
//  APPRO
//
//  Created by 정상윤 on 10/13/24.
//

enum StretchingPart: String, Identifiable, CaseIterable {
    
    case eyes, wrist, shoulder
    
    var id: Self { self }
    
    var title: String {
        rawValue.capitalized
    }
    
    var description: String {
        switch self {
        case .eyes:
            "Restore eye fatigue through stretching that rolls both eyes"
        case .wrist:
            "Restore wrist fatigue through stretching that fixes arms and turns wrists"
        case .shoulder:
            "Restore shoulder fatigue by stretching your shoulders left and right, up and down"
        }
    }
    
    var maxCount: Int {
        switch self {
        case .eyes:
            12
        case .wrist:
            6
        case .shoulder:
            3
        }
    }
    
    var tutorialInstructions: [TutorialInstruction] {
        switch self {
        case .eyes: [
            .init(instruction: "When you’re ready, pinch the lazy eyes in front of you.", isNextButtonRequired: false),
            .init(instruction: "You've waken the lazy eyes! Your mission is to cut off distracting thoughts from the lazy eyes.", isNextButtonRequired: true),
            .init(instruction: "Try to look and pinch the distracting thoughts to get rid of it. Hold for 2 seconds. Use only your eye movement.", isNextButtonRequired: false),
            .init(instruction: "Great! Stretching your eyes is the main focus in this content. Try to not to move your neck and body too much or it will move the eyes away from its work.", isNextButtonRequired: true)
            ]
        case .wrist: [
            .init(instruction: "When you’re ready, stretch your right arm forward and try to hold a fist.", isNextButtonRequired: false),
            .init(instruction: "You've gained the energy shooter! From now on, the ring reacts to your fist. Your mission is to hit all the targets with your energy shooter.", isNextButtonRequired: true),
            .init(instruction: "Bending your fist creates a sphere that keeps track of your fist rotation. Charge the energy by rotating the sphere around the ring. The ring will turn white if fully charged.", isNextButtonRequired: false),
            .init(instruction: "When charged enough, the ring will shoot the spiral energy. If not fully charged, the target won't disappear even if it's hit.", isNextButtonRequired: false),
            .init(instruction: "Great! Stretching your wrist is the main focus in this content. Hittable target differs for each wrist, so use both. Try not to move your body around too much.", isNextButtonRequired: true)
        ]
        case .shoulder: [
            .init(instruction: "When you’re ready, stretch your right arm forward and try to hold a fist.", isNextButtonRequired: false),
            .init(instruction: "You've summoned the rocket to your hand! From now on the rocket will follow your hand movement.", isNextButtonRequired: true),
            .init(instruction: "Your mission is to lead the rocket to every stars and complete the journey. To see the stars, try to hold a fist. If you want to rearrange stars, hold a fist again.", isNextButtonRequired: false),
            .init(instruction: "Try to carry the rocket to the stars without moving your legs. Use only your arm's movement.", isNextButtonRequired: false),
            .init(instruction: "Good! This time, when you reach the space station, keep your arm in the same position for 5 seconds to refuel the rocket.", isNextButtonRequired: false),
            .init(instruction: "Great! Stretching your shoulder is the main focus in this content. Try to fix your position in one spot.", isNextButtonRequired: true)
        ]
        }
    }
    
    var backgroundImageName: String {
        "\(self)_background"
    }
    
}

struct TutorialInstruction {
    var instruction: String
    var isNextButtonRequired: Bool
}
