//
//  HeadTracker.swift
//  APPRO
//
//  Created by 정상윤 on 11/7/24.
//

import ARKit
import RealityKit
import QuartzCore

final class HeadTracker: ObservableObject {
    
    let arSession = ARKitSession()
    let worldTracking = WorldTrackingProvider()
    
    init() {
        Task {
            guard WorldTrackingProvider.isSupported else {
                dump("WorldTrackingProvider is not supported on this device")
                return
            }
            
            do {
                try await arSession.run([worldTracking])
            } catch {
                dump(error)
            }
        }
    }
    
    deinit {
        arSession.stop()
    }
    
    func originFromDeviceTransform() -> simd_float4x4? {
        guard let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else { return nil }
        
        return deviceAnchor.originFromAnchorTransform
    }
    
}
