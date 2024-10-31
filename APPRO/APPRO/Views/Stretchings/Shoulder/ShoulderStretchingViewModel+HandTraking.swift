//
//  ShoulderStretchingViewModel+HandTraking.swift
//  APPRO
//
//  Created by Damin on 10/31/24.
//

import RealityKit
import ARKit
import SwiftUI

extension ShoulderStretchingViewModel {
    func startHandTrackingSession() async {
        do {
            if HandTrackingProvider.isSupported {
                try await session.run([handTrackingProvider])
            }
        } catch {
            print("ARKitSession error:", error)
        }
    }
    
    func updateHandTracking() async {
        for await update in handTrackingProvider.anchorUpdates {
            switch update.event {
            case .updated:
                let anchor = update.anchor
                if !anchor.isTracked {
                    continue
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
    }
    
    func computeTransformHandTracking() {
        // 오른손 계산
        if !isRightDone {
            guard let rightHandAnchor = latestHandTracking.right,
                  rightHandAnchor.isTracked else {
                return
            }
            
            //right
            rightHandModelEntity.thumbIntermediateBaseModelEntity.transform = getTransform(rightHandAnchor, .thumbIntermediateBase, rightHandModelEntity.thumbIntermediateBaseModelEntity.transform)
            rightHandModelEntity.indexFingerTipModelEntity.transform = getTransform(rightHandAnchor, .indexFingerTip, rightHandModelEntity.indexFingerTipModelEntity.transform)
            
            rightHandModelEntity.rocketEntity.transform = getTransform(rightHandAnchor, .middleFingerMetacarpal, rightHandModelEntity.rocketEntity.transform)
            
            if !isFirstPositioning {
                //TODO: isFirstPositioning 이 false가 된 후에는 isFistShowing을 확인할 필요가 없음
                if !isFistShowing  {
                    resetModelEntities()
                    createEntitiesOnEllipticalArc(handTransform: self.rightHandTransform)
                    isFistShowing = true
                }
                return
            }
            
            guard
                let jointA = rightHandAnchor.handSkeleton?.joint(.thumbIntermediateBase),
                let jointB = rightHandAnchor.handSkeleton?.joint(.indexFingerIntermediateTip) else { return  }
            
            guard jointA.isTracked && jointB.isTracked else { return }
            
            let jointATransfrom = matrix_multiply(
                rightHandAnchor.originFromAnchorTransform, jointA.anchorFromJointTransform
            ).columns.3.xyz
            
            let jointBTransfrom = matrix_multiply(
                rightHandAnchor.originFromAnchorTransform, jointB.anchorFromJointTransform
            ).columns.3.xyz
            
            let fingersDistance = distance(jointATransfrom, jointBTransfrom)
            
            if isFistShowing && fingersDistance > 0.1 {
                isFistShowing = false
            } else if !isFistShowing && fingersDistance < 0.05 {
                resetModelEntities()
                guard
                    let fistJoint = rightHandAnchor.handSkeleton?.joint(.middleFingerMetacarpal),
                    fistJoint.isTracked else {
                    return
                }
                let mulitypliedMatrix = matrix_multiply(
                    rightHandAnchor.originFromAnchorTransform, fistJoint.anchorFromJointTransform
                )
                self.rightHandTransform = Transform(matrix: mulitypliedMatrix)
                
                createEntitiesOnEllipticalArc(handTransform: self.rightHandTransform)
                isFistShowing = true
            } else {
                return
            }
            
        }
        // 왼손 계산
        else {
            guard let leftHandAnchor = latestHandTracking.left,
                  leftHandAnchor.isTracked else {
                return
            }
            //left
            leftHandModelEntity.thumbIntermediateBaseModelEntity.transform = getTransform(leftHandAnchor, .thumbIntermediateBase, leftHandModelEntity.thumbIntermediateBaseModelEntity.transform)
            leftHandModelEntity.indexFingerTipModelEntity.transform = getTransform(leftHandAnchor, .indexFingerTip, leftHandModelEntity.indexFingerTipModelEntity.transform)
            leftHandModelEntity.rocketEntity.transform = getTransform(leftHandAnchor, .middleFingerMetacarpal, leftHandModelEntity.rocketEntity.transform)
            leftHandModelEntity.rocketEntity.transform.rotation *= simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
            
            
            if !isFistShowing {
                resetModelEntities()
                
                createEntitiesOnEllipticalArc(handTransform: rightHandTransform)
                isFistShowing = true
            }
        }
    }
    
    func getTransform(_ anchor: HandAnchor, _ jointName: HandSkeleton.JointName, _ beforeTransform: Transform) -> Transform {
        let joint = anchor.handSkeleton?.joint(jointName)
        
        if ((joint?.isTracked) != nil) {
            //MARK: 두 변환을 결합하여 손의 특정 관절이 월드 좌표계에서 정확히 어디에 위치하는지를 구하기 위함입니다.
            let t = matrix_multiply(anchor.originFromAnchorTransform, (joint?.anchorFromJointTransform)!)
            var transform = Transform(matrix: t)
            
            // 로켓의 transform을 적용
            transform.scale = SIMD3<Float>(repeating: 0.1)
            return transform
        }
        return beforeTransform
    }
    
    func addRightHandAnchor() {
        let modelEntities = [
            rightHandModelEntity.indexFingerTipModelEntity,
            rightHandModelEntity.thumbIntermediateBaseModelEntity,
            rightHandModelEntity.rocketEntity
        ]
        
        for entity in modelEntities {
            contentEntity.addChild(entity)
            handEntities.append(entity)
        }
    }
    
    func addLeftHandAnchor() {
        let modelEntities = [
            leftHandModelEntity.indexFingerTipModelEntity,
            leftHandModelEntity.thumbIntermediateBaseModelEntity,
            leftHandModelEntity.rocketEntity
        ]
        
        for entity in modelEntities {
            contentEntity.addChild(entity)
            handEntities.append(entity)
        }
    }
}
