//
//  ShoulderStretchingTutorialViewModel+SceneSubscribe.swift
//  APPRO
//
//  Created by marty.academy on 11/13/24.
//

import SwiftUI
import ARKit
import RealityKit
import RealityKitContent

extension ShoulderStretchingTutorialViewModel {
    func subscribeSceneEvent(_ content: RealityViewContent) {
        _ = content.subscribe(to: SceneEvents.Update.self, on: nil) { event in
                guard let deviceAnchor = self.worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else { return }
                self.startingZ = deviceAnchor.originFromAnchorTransform.columns.3.z
        }
    }
}
