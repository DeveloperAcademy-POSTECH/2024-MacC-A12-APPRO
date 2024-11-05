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
    
    var tutorialInstructions: [String] {
        switch self {
        case .eyes:
            [
                "When you’re ready, pinch the lazy eyes in front of you.",
                "You've waken the lazy eyes! Your mission is to cut off distracting thoughts from the lazy eyes.",
                "Try to look and pinch the distracting thoughts to get rid of it. Hold for 2 seconds. Use only your eye movement.",
                "Great! Stretching your eyes is the main focus in this content. Try to not to move your neck and body too much or it will move the eyes away from its work."
            ]
        case .wrist:
            [
                "When you’re ready, stretch your right arm forward and try to hold a fist.",
                "You've gained the energy shooter! From now on, the ring reacts to your fist.",
                "Your mission is to hit all the targets with your energy shooter.",
                "Bending your fist creates a sphere that keeps track of your fist rotation. Charge the energy by rotating the sphere around the ring. The ring will turn black if fully charged.",
                "When charged enough, the ring will shoot the spiral energy. If not fully charged, the target won't disappear even if it's hit.",
                "Great! Stretching your wrist is the main focus in this content. Hittable target differs for each wrist, so use both. Try not to move your body around too much."
            ]
        case .shoulder:
            [
                "When you’re ready, stretch your right arm forward.",
                "You've summoned the probe to your hand! From now on the rocket will follow your hand movement.",
                "Your mission is to lead the probe to every stars and complete the journey.",
                "Try to carry the probe to the stars without moving your legs. Use only your arm's movement.",
                "Good. Now the probe needs to charge its fuel. Hold still for five seconds.",
                "Great! Stretching your shoulder is the main focus in this content. Try to fix your position in one spot."
            ]
        }
    }
    
    var backgroundImageName: String {
        "\(self)_background"
    }
    
}
