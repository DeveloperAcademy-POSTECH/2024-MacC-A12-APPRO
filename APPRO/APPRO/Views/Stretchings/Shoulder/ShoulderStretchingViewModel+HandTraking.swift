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
    
}

private extension ModelEntity {
    static func createHandEntity(isMarker: Bool = false)  -> ModelEntity {
        var modelEntity = ModelEntity()
        var clearMaterial = PhysicallyBasedMaterial()
        clearMaterial.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(scale: 0))
        if isMarker {
            modelEntity = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [clearMaterial])
            modelEntity.generateCollisionShapes(recursive: true)
            modelEntity.name = "Marker"
        } else {
            modelEntity = ModelEntity(mesh: .generateBox(size: 0.012), materials: [clearMaterial])
            modelEntity.name = "Finger"
        }
        return modelEntity
    }
}
