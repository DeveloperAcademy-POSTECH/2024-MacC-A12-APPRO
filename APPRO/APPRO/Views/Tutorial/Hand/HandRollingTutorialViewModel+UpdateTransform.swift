//
//  HandRollingTutorialViewModel.swift
//  APPRO
//
//  Created by marty.academy on 11/7/24.
//

import SwiftUI
import ARKit
import RealityKit
import RealityKitContent

extension HandRollingTutorialViewModel {
    
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
        let wristRingTransform = rightGuideRing.transform
        
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
            }
            return intersection3D
        }
        
        if rightGuideSphere.scale.x < 1  {
            rightGuideSphere.scale = .init(repeating: 1)
        }
            
        
        let directionVector = normalize(intersection3D - wristRingPosition)
        // 원 경계에 해당하는 지점 계산
        let pointOnBoundary = wristRingPosition + directionVector * radius
        return pointOnBoundary
    }
    
    private func applyLinearInterpolation (current : Float, previous : Float, factor:Float) -> Float {
        return previous + (current - previous) * factor
    }
    
    func playRotationChangeRingSound(_ newValue: Int) async {
        if newValue >= 3 {
            try? await playSpatialAudio(rightGuideRing, audioInfo: AudioFindHelper.handRotationThreeTimes)
        } else if newValue == 2 {
            try? await playSpatialAudio(rightGuideRing, audioInfo: AudioFindHelper.handRotationTwice)
        } else if newValue == 1 {
            try? await playSpatialAudio(rightGuideRing, audioInfo: AudioFindHelper.handRotationOnce)
        }
    }
}
