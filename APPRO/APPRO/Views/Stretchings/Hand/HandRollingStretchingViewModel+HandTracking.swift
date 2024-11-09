//
//  HandRollingStretchingViewModel+HandTracking.swift
//  APPRO
//
//  Created by marty.academy on 10/31/24.
//

import SwiftUI
import ARKit
import RealityKit

extension HandRollingStretchingViewModel {
    func start() async {
        do {
            if HandTrackingProvider.isSupported && WorldTrackingProvider.isSupported{
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
        if frameIndex % frameInterval == 0 {
            for await update in handTracking.anchorUpdates {
                switch update.event {
                case .updated:
                    let anchor = update.anchor
                    
                    guard anchor.isTracked else { continue }
                    
                    if anchor.chirality == .left {
                        latestHandTracking.left = anchor
                        isHandinFistShape(chirality: .left)
                    } else if anchor.chirality == .right {
                        latestHandTracking.right = anchor
                        isHandinFistShape(chirality: .right)
                    }
                    
                default:
                    break
                }
            }
        }
        
        frameIndex += 1
    }
    
    func isHandinFistShape(chirality: Chirality) {
        guard let handAnchor = chirality == .right ? latestHandTracking.right : latestHandTracking.left else { return  }
        
        guard
            let thumbJoint = handAnchor.handSkeleton?.joint(.thumbIntermediateBase),
            let indexJoint = handAnchor.handSkeleton?.joint(.indexFingerIntermediateTip),
            thumbJoint.isTracked && indexJoint.isTracked else { return }
        
        let thumbJointOriginalTransform = matrix_multiply(handAnchor.originFromAnchorTransform, thumbJoint.anchorFromJointTransform).columns.3
        let indexJointOriginalTransfrom = matrix_multiply(handAnchor.originFromAnchorTransform, indexJoint.anchorFromJointTransform).columns.3
        
        let distance = distance(thumbJointOriginalTransform, indexJointOriginalTransfrom)
        
        let isFistShape = distance <= 0.04
        let isPalmOpened = distance >= 0.09
        
        if chirality == .right {
            if isRightHandInFist {
                isRightHandInFist = !isPalmOpened
            } else {
                isRightHandInFist = isFistShape
            }
        } else {
            if isLeftHandInFist {
                isLeftHandInFist = !isPalmOpened
            } else {
                isLeftHandInFist = isFistShape
            }
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
