//
//  HandGestureModel.swift
//  APPRO
//
//  Created by marty.academy on 10/20/24.
//

import ARKit
import SwiftUI
import RealityKit

@MainActor
@Observable
final class HandGestureModel {
    
    let session = ARKitSession()
    var handTracking = HandTrackingProvider()
    
    var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    var rotationCount = 0
    
    private var lastRotationAxisX: Float = 0.0
    private var isIncreasing: Bool = false
    private var hasCrossedZero: Bool = false
    
    let threshold: Float = 0.05
    
    deinit {
        session.stop()
    }
    
    struct HandsUpdates {
        var left: HandAnchor?
        var right: HandAnchor?
    }
    
    func start() async {
        do {
            if HandTrackingProvider.isSupported {
                try await session.run([handTracking])
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
                    
                } else if anchor.chirality == .right {
                    latestHandTracking.right = anchor
                    trackThumbKnuckleRotation(anchor: anchor)
                }
            default:
                break
            }
        }
    }
    
    func trackThumbKnuckleRotation(anchor: HandAnchor) -> Void {
        let joint = anchor.handSkeleton?.joint(.thumbIntermediateBase)

        if let val = joint {
            let t = matrix_multiply(latestHandTracking.right!.originFromAnchorTransform, val.anchorFromJointTransform)
            let currentRotation = Transform(matrix: t).rotation.axis

            let currentX = currentRotation.z
            
            if abs(currentX - lastRotationAxisX) > threshold {
                if currentX > lastRotationAxisX {
                    isIncreasing = true
                }
                else if currentX < lastRotationAxisX {
                    isIncreasing = false
                }
                
                if !hasCrossedZero && currentX < 0 && isIncreasing {
                    hasCrossedZero = true
                } else if hasCrossedZero && currentX > 0 && !isIncreasing {
                    rotationCount += 1
                    hasCrossedZero = false
                }
                lastRotationAxisX = currentX
            }
        }
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
