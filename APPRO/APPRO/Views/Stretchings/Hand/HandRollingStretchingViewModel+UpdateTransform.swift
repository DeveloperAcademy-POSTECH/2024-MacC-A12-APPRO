//
//  HandRollingStretchingViewModel+UpdateTransform.swift
//  APPRO
//
//  Created by marty.academy on 10/31/24.
//

import SwiftUI
import ARKit
import RealityKit
import RealityKitContent

extension HandRollingStretchingViewModel {
    
    func calArmTransform(_ beforeTransform: Transform, chirality : Chirality) -> Transform {
        guard let anchor = chirality == .right ? latestHandTracking.right : latestHandTracking.left else { return beforeTransform }
        let joint = anchor.handSkeleton?.joint(.forearmArm)
        
        if ((joint?.isTracked) != nil) {
            var t = matrix_multiply(anchor.originFromAnchorTransform, (joint?.anchorFromJointTransform)!)
            
            let directionColumns = t.columns.0
            let directionVector = simd_float3(x: directionColumns.x, y: directionColumns.y, z: directionColumns.z)
            
            let ringLocation = chirality == .right ? simd_float3(x: t.columns.3.x, y: t.columns.3.y , z: t.columns.3.z ) + ( directionVector * 0.4 ) : simd_float3(x: t.columns.3.x, y: t.columns.3.y , z: t.columns.3.z ) - ( directionVector * 0.4 )
            
            t.columns.3.x = ringLocation.x
            t.columns.3.y = ringLocation.y
            t.columns.3.z = ringLocation.z
            
            return Transform(matrix: t)
        }
        return beforeTransform
    }
    
    func calculateIntersectionWithWristRingPlane(chirality : Chirality) -> simd_float3? {
        let wristRingTransform = chirality == .right ? rightGuideRing.transform : leftGuideRing.transform
        
        let middleKnucklePosition = getJointPosition(.middleFingerKnuckle, chirality: chirality)
        let vector = middleKnucklePosition - getJointPosition(.wrist, chirality: chirality)
        let normalizedVector = normalize(vector)
        
        let wristRingY = simd_float3(wristRingTransform.matrix.columns.1.x,
                                     wristRingTransform.matrix.columns.1.y,
                                     wristRingTransform.matrix.columns.1.z)
        let wristRingZ = simd_float3(wristRingTransform.matrix.columns.2.x,
                                     wristRingTransform.matrix.columns.2.y,
                                     wristRingTransform.matrix.columns.2.z)
        
        let planeNormal = cross(wristRingY, wristRingZ)
        let wristRingPosition = simd_float3(wristRingTransform.matrix.columns.3.x,
                                            wristRingTransform.matrix.columns.3.y,
                                            wristRingTransform.matrix.columns.3.z)
        
        let denominator = dot(planeNormal, normalizedVector)
        if abs(denominator) < 1e-6 {
            return nil // 벡터가 평면과 평행한 경우 교차점이 없음
        }
        
        let t = dot(planeNormal, wristRingPosition - middleKnucklePosition) / denominator
        
        let intersection3D = middleKnucklePosition + normalizedVector * t
        
        let distanceToCenter = length(intersection3D - wristRingPosition)
        if distanceToCenter <= ( radius / 4 )  {
            if chirality == .right {
                rightGuideSphere.scale = .init(repeating: 0.01)
                if rightRotationCount > 0 && !rightLaunchState {
                    DispatchQueue.main.async {
                        self.rightLaunchState = true //TODO: 회전폭 반경은 더욱 좁게 설정되어야할 수도 있음.
                    }
                }
            } else {
                leftGuideSphere.scale = .init(repeating: 0.01)
                if leftRotationCount > 0 && !leftLaunchState {
                    DispatchQueue.main.async {
                        self.leftLaunchState = true //TODO: 회전폭 반경은 더욱 좁게 설정되어야할 수도 있음.
                    }
                }
                
            }
            return intersection3D
        }
        
        rightGuideSphere.scale = .init(repeating: 1)
        leftGuideSphere.scale = .init(repeating: 1)
        
        let directionVector = normalize(intersection3D - wristRingPosition)
        // 원 경계에 해당하는 지점 계산
        let pointOnBoundary = wristRingPosition + directionVector * radius
        return pointOnBoundary
    }
}
