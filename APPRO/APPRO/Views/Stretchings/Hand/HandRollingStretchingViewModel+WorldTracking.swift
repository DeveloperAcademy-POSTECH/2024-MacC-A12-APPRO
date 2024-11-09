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
    func getHeadHeight() async {
        guard let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else { return }
        startingHeight = deviceAnchor.originFromAnchorTransform.columns.3.y
    }
}
