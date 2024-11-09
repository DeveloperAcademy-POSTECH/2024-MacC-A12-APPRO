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
                        isHandInFistShape(chirality: .left)
                    } else if anchor.chirality == .right {
                        latestHandTracking.right = anchor
                        isHandInFistShape(chirality: .right)
                    }
                    
                default:
                    break
                }
            }
        }
        
        frameIndex += 1
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
        let isPalmOpened = distance >= 0.09
        
        updateFistReader(for: chirality, isFistShape: isFistShape, isPalmOpened: isPalmOpened)
    }
    
    private func updateFistReader(for chirality: Chirality, isFistShape: Bool, isPalmOpened: Bool) {
        var fistReader = (chirality == .right ? fistReaderRight : fistReaderLeft)
        let isHandInFist = (chirality == .right ? isRightHandInFist : isLeftHandInFist)
        
        // 주먹을 쥔 상태라면 손을 펴야지만 값을 인식, 그렇지 않다면 주먹인지 아닌지에 대한 값을 추가한다. : 명확한 변화를 반영하기 위함.
        fistReader.append(isHandInFist ? !isPalmOpened : isFistShape)
        
        // 60프레임중 12프레임 연속으로 동일한 값을 추적하기 위한 프레임 threshold
        if fistReader.count > 12 {
            fistReader.removeFirst()
        }
        
        // 판독 결과가 일관적일 때 상태 변경
        if isAllSameResultOnFistReading(readingData: fistReader), fistReader.first != isHandInFist {
            if chirality == .right {
                isRightHandInFist = fistReader.first!
                fistReaderRight = fistReader
            } else {
                isLeftHandInFist = fistReader.first!
                fistReaderLeft = fistReader
            }
        } else {
            if chirality == .right {
                fistReaderRight = fistReader
            } else {
                fistReaderLeft = fistReader
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
