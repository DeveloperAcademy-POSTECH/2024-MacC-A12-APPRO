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
        case .neck:
            "Restore neck fatigue by stretching your head up and down and left and right"
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
                "When you’re ready, pinch the lazy eyes in front of you.",
                "You've waken the lazy eyes! Your mission is to cut off distracting thoughts from the lazy eyes.",
                "Try to look and pinch the distracting thoughts to get rid of it. Hold for 2 seconds. Use only your eye movement.",
                "Great! Stretching your eyes is the main focus in this content. Try to not to move your neck and body too much or it will move the eyes away from its work."
            ]
        case .wrist:
            [
                "When you’re ready, stretch your right arm forward and try to hold a fist.",
                "You've gained the energy shooter! From now on, the ring reacts to your fist. Your mission is to hit all the targets with your energy shooter.",
                "Bending your fist creates a sphere that keeps track of your fist rotation. Charge the energy by rotating the sphere around the ring. The ring will turn white if fully charged.",
                "When charged enough, the ring will shoot the spiral energy. If not fully charged, the target won't disappear even if it's hit.",
                "Great! Stretching your wrist is the main focus in this content. Hittable target differs for each wrist, so use both. Try not to move your body around too much."
            ]
        case .shoulder:
            [
                "When you’re ready, stretch your right arm forward and try to hold a fist.",
                "You've summoned the rocket to your hand! From now on the rocket will follow your hand movement.",
                "Your mission is to lead the rocket to every stars and complete the journey. To see the stars, try to hold a fist. If you want to rearrange stars, hold a fist again.",
                "Try to carry the rocket to the stars without moving your legs. Use only your arm's movement.",
                "Good! This time, when you reach the space station, keep your arm in the same position for 5 seconds to refuel the rocket.",
                "Great! Stretching your shoulder is the main focus in this content. Try not to move your body around too much."
            ]
        case .neck:
            [
                "When you're ready, pinch the piggy in front of you",
                "You've waken the piggy up! From now on, the piggy will follow your neck movement, Your mission is to lead the piggy to its favorite coins. To show the coins, pinch the piggy again",
                "Try to move the pig upward to give coins. Use only your neck movement, without moving your body.",
                /* 위로 움직여라, 아래로 움직여라고 움직이는 것과 제일 끝지점에서 멈추는 동작에 대한 가이드라인이 동시에 들어가야함.
                 반드시 지정한대로 해줄 것인지? 1코인 -> 2코인 -> 3코인
                 위로가면 코인의 반, 아래로가면 별의 전체를 써야하는데 이에 대한 디자인은 어떻게 할 것인지?
                 위로가야할 때에, 본게임에서 사인, (위로가야한다)는을 어떻게 줄 것인지?
                 */
                "Good. Now the piggy needs to digest the coins for a bit. Hold still for five seconds.",
                "Great! Stretching your neck is the main focus in this content. Try not to move your body around too much."
            ]
        }
    }
    
    var backgroundImageName: String {
        "\(self)_background"
    }
    
}
