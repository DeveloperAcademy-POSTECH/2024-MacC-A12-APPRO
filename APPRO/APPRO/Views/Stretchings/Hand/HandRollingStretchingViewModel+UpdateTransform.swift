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
    
    func updateStartingComponentsTransform(_ content: RealityViewContent) {
        guard let startingObj = content.entities.first(where: {$0.name == "StartingObject"}) else { return }
        startingObj.transform.translation = .init(x: 0, y: startingHeight - 0.1, z: -1.0)
    }
    
    func updateTargetsComponentTransform(_ content: RealityViewContent) {
        
        areTargetTranslationUpdated = true
        
        rightTargetEntities[0].transform.translation = .init(x: -0.6, y: startingHeight - 0.2, z: -0.8)
        rightTargetEntities[1].transform.translation = .init(x: -0.6, y: startingHeight + 0.4, z: -1.0)
        rightTargetEntities[2].transform.translation = .init(x: 0.9, y: startingHeight + 0.3 , z: -0.7)
        
        leftTargetEntities[0].transform.translation = .init(x: -0.35, y: startingHeight, z: -1.0)
        leftTargetEntities[1].transform.translation = .init(x: 0.5, y: startingHeight + 0.2, z: -1.0)
        leftTargetEntities[2].transform.translation = .init(x: 0.9, y: startingHeight - 0.2, z: -0.6)
    }
    
    func updateGuideComponentsTransform(_ content: RealityViewContent, chirality:  Chirality) {
        
        let chiralityString = chirality == .right ? "Right" : "Left"
        
        guard let rightGuideRing = content.entities.first(where: {$0.name == "Ring_\(chiralityString)"}) else { return }
        rightGuideRing.transform = calArmTransform(rightGuideRing.transform, chirality: chirality)
        
        guard let rightGuideSphere = content.entities.first(where: {$0.name == "GuideSphere_\(chiralityString)"}) else { return }
        rightGuideSphere.position = calculateIntersectionWithWristRingPlane(chirality: chirality) ?? rightGuideSphere.position
    }
    
    func calArmTransform(_ beforeTransform: Transform, chirality : Chirality) -> Transform {
        guard let anchor = chirality == .right ? latestHandTracking.right : latestHandTracking.left else { return beforeTransform }
        let joint = anchor.handSkeleton?.joint(.forearmArm)
        
        let smoothingFactor: Float = 0.05
        
        if ((joint?.isTracked) != nil) {
            var t = matrix_multiply(anchor.originFromAnchorTransform, (joint?.anchorFromJointTransform)!)
            
            let directionColumns = t.columns.0
            let directionVector = simd_float3(x: directionColumns.x, y: directionColumns.y, z: directionColumns.z)
            
            let ringLocation = chirality == .right ? simd_float3(x: t.columns.3.x, y: t.columns.3.y , z: t.columns.3.z ) + ( directionVector * 0.4 ) : simd_float3(x: t.columns.3.x, y: t.columns.3.y , z: t.columns.3.z ) - ( directionVector * 0.4 )
            
            
            t.columns.3.x = applyLinearInterpolation(current: ringLocation.x, previous: beforeTransform.translation.x, factor: smoothingFactor)
            t.columns.3.y = applyLinearInterpolation(current: ringLocation.y, previous: beforeTransform.translation.y, factor: smoothingFactor)
            t.columns.3.z = applyLinearInterpolation(current: ringLocation.z, previous: beforeTransform.translation.z, factor: smoothingFactor)
            
            var newTransform = Transform(matrix: t)
            
            let currentRotation = newTransform.rotation
            let smoothedRotation = simd_normalize(simd_slerp(beforeTransform.rotation, currentRotation, smoothingFactor))
            
            newTransform.rotation = smoothedRotation
            
            return newTransform
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
        if distanceToCenter <= ( radius / 8 )  {
            if chirality == .right {
                rightGuideSphere.scale = .init(repeating: 0.01)
                if rightRotationCount > 0 && !rightLaunchState {
                    DispatchQueue.main.async {
                        self.rightLaunchState = true
                    }
                }
            } else {
                leftGuideSphere.scale = .init(repeating: 0.01)
                if leftRotationCount > 0 && !leftLaunchState {
                    DispatchQueue.main.async {
                        self.leftLaunchState = true
                    }
                }
            }
            return intersection3D
        }
        
        if rightGuideSphere.scale.x < 1  {
            rightGuideSphere.scale = .init(repeating: 1)
        }
            
        if leftGuideSphere.scale.x < 1 {
            leftGuideSphere.scale = .init(repeating: 1)
        }
        
        
        
        let directionVector = normalize(intersection3D - wristRingPosition)
        // 원 경계에 해당하는 지점 계산
        let pointOnBoundary = wristRingPosition + directionVector * radius
        return pointOnBoundary
    }
    
    private func applyLinearInterpolation (current : Float, previous : Float, factor:Float) -> Float {
        return previous + (current - previous) * factor
    }
    
    func playRotationChangeRingSound(_ newValue: Int, chirality : Chirality) {
        let guideRing = chirality == .left ? leftGuideRing : rightGuideRing
        
        if newValue >= 3 {
            soundHelper.playSound(.handRotationThreeTimes, on: guideRing)
        } else if newValue == 2 {
            soundHelper.playSound(.handRotationTwice, on: guideRing)
        } else if newValue == 1 {
            soundHelper.playSound(.handRotationOnce, on: guideRing)
        }
    }
}
