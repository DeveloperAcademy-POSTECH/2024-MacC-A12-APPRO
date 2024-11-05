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
}
