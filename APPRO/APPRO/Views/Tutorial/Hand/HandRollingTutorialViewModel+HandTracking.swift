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
                try await session.run([handTracking])
            } else {
                print("hand tracking: \(HandTrackingProvider.isSupported)")
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
        }
    }
    
    
    func isHandInFistShape(chirality: Chirality) {
        guard let handAnchor = latestHandTracking.right,
              let thumbJoint = handAnchor.handSkeleton?.joint(.thumbIntermediateBase),
              let indexJoint = handAnchor.handSkeleton?.joint(.indexFingerIntermediateTip),
              thumbJoint.isTracked, indexJoint.isTracked else { return }
        
        let thumbTransform = matrix_multiply(handAnchor.originFromAnchorTransform, thumbJoint.anchorFromJointTransform).columns.3
        let indexTransform = matrix_multiply(handAnchor.originFromAnchorTransform, indexJoint.anchorFromJointTransform).columns.3
        
        let distance = distance(thumbTransform, indexTransform)
        let isFistShape = distance <= 0.04
        let isPalmOpened = distance >= 0.09
        
        updateFistReader(for: chirality, isFistShape: isFistShape, isPalmOpened: isPalmOpened)
    }
    
    private func updateFistReader(for chirality: Chirality, isFistShape: Bool, isPalmOpened: Bool) {
        var fistReader = fistReaderRight
        let isHandInFist = isRightHandInFist
        
        fistReader.append(isHandInFist ? !isPalmOpened : isFistShape)
        
        if fistReader.count > 12 {
            fistReader.removeFirst()
        }
        
        if isAllSameResultOnFistReading(readingData: fistReader), fistReader.first != isHandInFist {
            if chirality == .right {
                isRightHandInFist = fistReader.first!
                fistReaderRight = fistReader
            }
        } else {
            if chirality == .right {
                fistReaderRight = fistReader
            }
        }
    }
    
    func isAllSameResultOnFistReading(readingData: [Bool]) -> Bool {
        guard let firstData = readingData.first else { return false }
        return readingData.allSatisfy { $0 == firstData }
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
