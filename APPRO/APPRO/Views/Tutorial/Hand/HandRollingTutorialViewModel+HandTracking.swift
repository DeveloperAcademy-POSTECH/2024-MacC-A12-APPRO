//
//  HandRollingTutorialViewModel.swift
//  APPRO
//
//  Created by marty.academy on 11/7/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit


extension HandRollingTutorialViewModel {
    func start() async {
        do {
            if HandTrackingProvider.isSupported {
                try await session.run([handTracking, worldTracking])
            } else {
                print("hand tracking: \(HandTrackingProvider.isSupported)")
                print("world tracking: \(WorldTrackingProvider.isSupported)")
            }
            
        } catch {
            print("ARKitSession error:", error)
        }
    }
    
    func publishHandTrackingUpdates() async {
        
        for await update in handTracking.anchorUpdates {
            switch update.event {
            case .updated:
                let anchor = update.anchor
                
                guard anchor.isTracked else { continue }
                
                if anchor.chirality == .left {
                    latestHandTracking.left = anchor
                    if !isLeftHandInFist {
                        isHandInFistShape(chirality: .left)
                    }
                } else if anchor.chirality == .right {
                    latestHandTracking.right = anchor
                    if !isRightHandInFist {
                        isHandInFistShape(chirality: .right)
                    }
                }
                
            default:
                break
            }
        }
    }

    func isHandInFistShape(chirality: Chirality) {
        guard let handAnchor = (chirality == .right ? latestHandTracking.right : latestHandTracking.left),
              let thumbJoint = handAnchor.handSkeleton?.joint(.thumbIntermediateBase),
              let indexJoint = handAnchor.handSkeleton?.joint(.indexFingerIntermediateTip),
              thumbJoint.isTracked, indexJoint.isTracked else { return }
        
        let thumbTransform = matrix_multiply(handAnchor.originFromAnchorTransform, thumbJoint.anchorFromJointTransform).columns.3
        let indexTransform = matrix_multiply(handAnchor.originFromAnchorTransform, indexJoint.anchorFromJointTransform).columns.3
        
        let distance = distance(thumbTransform, indexTransform)
        let isFistShape = distance <= 0.04
        
        if chirality == .left {
            isLeftHandInFist = isFistShape
        } else {
            isRightHandInFist = isFistShape
        }
    }
    func getJointPosition(_ jointName: HandSkeleton.JointName, chirality : Chirality) -> simd_float3 {
        guard let handAnchor = chirality == .right ? latestHandTracking.right : latestHandTracking.left else { return .init() }
        guard let joint = handAnchor.handSkeleton?.joint(jointName) else { return .init() }
        
        let selectedJointOriginalTransfrom = matrix_multiply(handAnchor.originFromAnchorTransform, joint.anchorFromJointTransform).columns.3
        
        return simd_float3(selectedJointOriginalTransfrom.x, selectedJointOriginalTransfrom.y, selectedJointOriginalTransfrom.z)
    }
    
    func monitorSessionEvents() async {
        for await event in session.events {
            switch event {
            case .authorizationChanged(let type, let status):
                if type == .handTracking && status != .allowed {
                }
                
            default:
                print("Session event \(event)")
            }
        }
    }
}
