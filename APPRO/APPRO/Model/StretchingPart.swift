//
//  Stretching.swift
//  APPRO
//
//  Created by 정상윤 on 10/13/24.
//

enum StretchingPart: String, Identifiable, CaseIterable {
    
    case eyes, wrist, shoulder, neck
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .eyes:
            String(localized: "Eyes")
        case .wrist:
            String(localized: "Wrist")
        case .shoulder:
            String(localized: "Shoulder")
        case .neck:
            String(localized: "Neck")
        }
    }
    
    var description: String {
        switch self {
        case .eyes:
            String(localized: "Restore eye fatigue through stretching that rolls both eyes")
        case .wrist:
            String(localized: "Restore wrist fatigue through stretching that fixes arms and turns wrists")
        case .shoulder:
            String(localized: "Restore shoulder fatigue by stretching your shoulders left and right")
        case .neck:
            String(localized: "Restore neck fatigue by stretching your head up and down and left and right")
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
        case .neck:
            3
        }
    }
    
    var tutorialInstructions: [String] {
        switch self {
        case .eyes:
            [
                String(localized: "When you’re ready, pinch the lazy eyes in front of you."),
                String(localized: "You've waken the lazy eyes! Your mission is to cut off distracting thoughts from the lazy eyes."),
                String(localized: "Try to look and long press the distracting thoughts. Hold it for a second to get rid of it. They will keep disturbing the eyes if not removed!"),
                String(localized: "Great! Stretching your eyes is the main focus in this content. Try to not to move your neck and body too much or it will move the eyes away from its work.")
            ]
        case .wrist:
            [
                String(localized: "When you’re ready, stretch your right arm forward and try to hold a fist to gain the energy."),
                String(localized: "You've gained the energy shooter! From now on, the ring reacts to your fist. Your mission is to hit all the targets with your energy shooter."),
                String(localized: "Bending your fist creates a sphere that keeps track of your fist rotation. Charge the energy by rotating the sphere around the ring. The ring will turn white if fully charged."),
                String(localized: "When charged enough, the ring will shoot the spiral energy. If not fully charged, the target won't disappear even if it's hit."),
                String(localized: "Great! Stretching your wrist is the main focus in this content. Hittable target differs for each wrist, so use both. Try not to move your body around too much.")
            ]
        case .shoulder:
            [
                String(localized: "When you’re ready, stretch your right arm forward and try to hold a fist to summon the rocket."),
                String(localized: "You've summoned the rocket to your hand! From now on the rocket will follow your hand movement."),
                String(localized: "Your mission is to lead the rocket to every stars and complete the journey. To see the stars, try to hold a fist. If you want to rearrange stars, hold a fist again."),
                String(localized: "Try to carry the rocket to the stars without moving your legs. Use only your arm's movement."),
                String(localized: "Good! This time, when you reach the space station, keep your arm in the same position for 5 seconds to refuel the rocket."),
                String(localized: "Great! Stretching your shoulder is the main focus in this content. Try not to move your body around too much.")
            ]
        case .neck:
            [
                String(localized: "When you're ready, pinch the piggy in front of you"),
                String(localized: "You've waken the piggy up! Your mission is to lead the piggy to coins and hold for 5 seconds until the pig finishes shopping at the end of the coins. To get started, look straight ahead and pinch again."),
                String(localized: "Try to move the pig without moving your body. Use only your neck movement."),
                String(localized: "Great! Stretching your neck is the main focus in this content. Try not to move your body around too much.")
            ]
        }
    }
    
    var backgroundImageName: String {
        "\(self)_background"
    }
    
}
