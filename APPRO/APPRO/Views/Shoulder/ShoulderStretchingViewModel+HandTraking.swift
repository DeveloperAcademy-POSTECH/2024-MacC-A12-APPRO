//
//  AppModel+HandTraking.swift
//  ParabolaTest
//
//  Created by Damin on 10/15/24.
//

import RealityKit
import ARKit
import SwiftUI

struct HandsUpdates {
    var left: HandAnchor?
    var right: HandAnchor?
}

extension ShoulderStretchingViewModel {
    func start() async {
        do {
            if HandTrackingProvider.isSupported {
                try await session.run([handTrackingProvider])
            }
        } catch {
            print("ARKitSession error:", error)
        }
    }
    
    func handTracking_2() async {
        for await update in handTrackingProvider.anchorUpdates {
            switch update.event {
            case .updated:
                let anchor = update.anchor
                                
                guard anchor.isTracked else { continue }
//                if !anchor.isTracked {
//                    dump("anchor is not tracked")
//                    return
//                }
                if anchor.chirality == .left {
                    self.latestHandTracking.left = anchor
                } else if anchor.chirality == .right {
                    self.latestHandTracking.right = anchor
                }
            default:
                break
            }
        }
    }
    
    func handTracking() {
        guard HandTrackingProvider.isSupported else { return }
        
        Task { @MainActor in
            do {
                try await session.run([handTrackingProvider])
                for await update in handTrackingProvider.anchorUpdates {
                    switch update.event {
                    case .updated:
                        let anchor = update.anchor
                        if !anchor.isTracked {
                            return
                        }
                        if anchor.chirality == .left {
                            self.latestHandTracking.left = anchor
                        } else if anchor.chirality == .right {
                            self.latestHandTracking.right = anchor
                        }
                    default:
                        break
                    }
                }
            } catch {
                print("Error starting hand tracking: \(error)")
            }
        }
    }
    
    func computeTransformHandTracking() {
        guard let leftHandAnchor = latestHandTracking.left,
              let rightHandAnchor = latestHandTracking.right,
              leftHandAnchor.isTracked, rightHandAnchor.isTracked else {
            return
        }
        
        rightThumbIntermediateBaseModelEntity.transform = getTransform(rightHandAnchor, .thumbIntermediateBase,rightThumbIntermediateBaseModelEntity.transform)
        
        rightIndexFingerTipModelEntity.transform = getTransform(rightHandAnchor, .indexFingerTip,rightIndexFingerTipModelEntity.transform)
        rightMiddleFingerKnuckleModelEntity.transform = getTransform(rightHandAnchor, .middleFingerKnuckle,rightMiddleFingerKnuckleModelEntity.transform)
        
        guard
            let jointA = rightHandAnchor.handSkeleton?.joint(.thumbIntermediateBase),
            let jointB = rightHandAnchor.handSkeleton?.joint(.indexFingerIntermediateTip),
            jointA.isTracked && jointB.isTracked else { return  }
        
        //TODO: 두 변환을 결합하여 손의 특정 관절이 월드 좌표계에서 정확히 어디에 위치하는지를 구하기 위함입니다.
        
        let jointATransfrom = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, jointA.anchorFromJointTransform
        ).columns.3.xyz
        
        let jointBTransfrom = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, jointB.anchorFromJointTransform
        ).columns.3.xyz
        
        let fingersDistance = distance(jointATransfrom, jointBTransfrom)
        
        if isFistShowing && fingersDistance > 0.08 {
            isFistShowing = false
        }else if !isFistShowing && fingersDistance < 0.05 {
            resetChildEntities()
            guard
                let fistJoint = rightHandAnchor.handSkeleton?.joint(.littleFingerKnuckle),
                fistJoint.isTracked else { return  }
            let mulitypliedMatrix = matrix_multiply(
                rightHandAnchor.originFromAnchorTransform, fistJoint.anchorFromJointTransform
            )
            
            createEntitiesOnEllipticalArc(handTransform: Transform(matrix: mulitypliedMatrix))
            isFistShowing = true
        }
    }
    
    func getTransform(_ anchor: HandAnchor, _ jointName: HandSkeleton.JointName, _ beforeTransform: Transform) -> Transform {
        let joint = anchor.handSkeleton?.joint(jointName)
        
        if ((joint?.isTracked) != nil) {
            //MARK: 두 변환을 결합하여 손의 특정 관절이 월드 좌표계에서 정확히 어디에 위치하는지를 구하기 위함입니다.
            let t = matrix_multiply(anchor.originFromAnchorTransform, (joint?.anchorFromJointTransform)!)
            return Transform(matrix: t)
        }
        return beforeTransform
        
    }
    
    func addHandAnchor() {
        let modelEntities = [
            rightThumbIntermediateBaseModelEntity,//3
            rightIndexFingerTipModelEntity, //10
            rightMiddleFingerKnuckleModelEntity
        ]
        
        for entity in modelEntities {
            contentEntity.addChild(entity)
        }
    }
    
}
