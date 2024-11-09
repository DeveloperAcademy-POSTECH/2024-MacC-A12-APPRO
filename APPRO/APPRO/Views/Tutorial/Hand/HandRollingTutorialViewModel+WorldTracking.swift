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
    func getHeadHeight() async {
        guard let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else { return }
        startingHeight = deviceAnchor.originFromAnchorTransform.columns.3.y
    }
}
