//
//  File.swift
//  APPRO
//
//  Created by Damin on 11/5/24.
//

import ARKit
import RealityKit

extension ShoulderStretchingViewModel {
    
    func computEntryRocketForTutorial(minimumDistance: Float)  {
        guard let rightHandAnchor = latestHandTracking.right,
              rightHandAnchor.isTracked else {
            return
        }
        
        handRocketEntity.transform = getTransform(rightHandAnchor, .middleFingerMetacarpal, handRocketEntity.transform)
        
        guard
            let fistJoint = rightHandAnchor.handSkeleton?.joint(.middleFingerMetacarpal),
            fistJoint.isTracked else {
            return
        }
        let mulitypliedMatrix = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, fistJoint.anchorFromJointTransform
        )
        self.rightHandTransform = Transform(matrix: mulitypliedMatrix)
                
        if !isEntryEnd && abs(rightHandTransform.translation.z) > minimumDistance {
            self.rightHandTransform.scale = .init(x: 0.1, y: 0.1, z: 0.1)
            playEntryRocketAnimation()
            isEntryEnd = true
        }
    }
    
    func computeTransformForTutorial() {
        guard let rightHandAnchor = latestHandTracking.right,
              rightHandAnchor.isTracked else {
            return
        }
        
        //right
        handModelEntity.thumbIntermediateBaseModelEntity.transform = getTransform(rightHandAnchor, .thumbIntermediateBase, handModelEntity.thumbIntermediateBaseModelEntity.transform)
        handModelEntity.indexFingerTipModelEntity.transform = getTransform(rightHandAnchor, .indexFingerTip, handModelEntity.indexFingerTipModelEntity.transform)
        
        handRocketEntity.transform = getTransform(rightHandAnchor, .middleFingerMetacarpal, handRocketEntity.transform)
        
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
            reCreateRightStars()
        } else {
            return
        }
    }
    
}
