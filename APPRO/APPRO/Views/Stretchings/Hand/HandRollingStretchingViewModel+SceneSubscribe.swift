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

extension HandRollingStretchingViewModel {
    
    func subscribeSceneEvent(_ content: RealityViewContent) {
        _ = content.subscribe(to: SceneEvents.Update.self, on: nil) { event in
            if self.startingHeight == 0 {
                guard let deviceAnchor = self.worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else { return }
                self.startingHeight = deviceAnchor.originFromAnchorTransform.columns.3.y
            }
        }
    }
}
