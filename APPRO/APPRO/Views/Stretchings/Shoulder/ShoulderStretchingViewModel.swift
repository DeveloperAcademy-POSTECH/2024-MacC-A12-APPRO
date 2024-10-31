//
//  ShoulderStretchingViewModel.swift
//  APPRO
//
//  Created by Damin on 10/31/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

@Observable
@MainActor
final class ShoulderStretchingViewModel {
    
    var contentEntity = Entity()
    var modelEntities: [Entity] = []
    var handEntities: [Entity] = []
    
    let session = ARKitSession()
    var handTrackingProvider = HandTrackingProvider()
    var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    // right
    var rightThumbIntermediateBaseModelEntity = ModelEntity.createHandEntity()
    var rightIndexFingerTipModelEntity = ModelEntity.createHandEntity()
    var rightRocketEntity = ModelEntity.createHandEntity(isMarker: true)
    // left
    var leftIndexFingerIntermediateBaseModelEntity = ModelEntity.createHandEntity()
    var leftIndexFingerTipModelEntity = ModelEntity.createHandEntity()
    var leftRocketEntity = ModelEntity.createHandEntity(isMarker: true)
    
    var isFistShowing: Bool = false
    var isFirstPositioning: Bool = true
    var isRightDone: Bool = false
    var rightHandTransform = Transform()
    
    func resetModelEntities() {
        modelEntities.forEach { entity in
            entity.removeFromParent()
        }
        modelEntities = []
    }
    
    func setupRocketEntity()  {
        Task {
            if let rootEntity = try? await Entity(named: "Shoulder/RocketScene.usda", in: realityKitContentBundle) {
                rightRocketEntity.generateCollisionShapes(recursive: true)
                rightRocketEntity.addChild(rootEntity)
                
                let leftRootEntity = rootEntity.clone(recursive: true)
                leftRocketEntity.generateCollisionShapes(recursive: true)
                leftRocketEntity.addChild(leftRootEntity)
            }
        }
    }
    
    // 어깨 중심을 기준으로 포물선 경로의 좌표를 생성하는 함수
    func generateUniformEllipseArcPoints(
        centerPosition: SIMD3<Float>,
        numPoints: Int,
        startPoint: SIMD3<Float>,  // 손의 위치를 시작점으로 받음
        arcSpan: Float,
        isRightSide: Bool
    ) -> [SIMD3<Float>] {
        var points: [SIMD3<Float>] = []
        
        let b: Float = abs(centerPosition.z - startPoint.z) // 타원의 단축 반지름
        let a: Float = b * 1.5  // 타원의 장축 반지름
        let y: Float = centerPosition.y  // Y 좌표는 어깨의 Y 좌표로 설정

        // startPoint와 centerPosition 사이의 벡터를 이용하여 startAngle 계산
        let deltaX = startPoint.x - centerPosition.x
        let deltaZ = startPoint.z - centerPosition.z
        // atan2를 사용하여 X, Z 평면에서의 각도(라디안)를 계산
        let startAngle = atan2(deltaZ, deltaX)  // 각도는 Z축을 기준으로 계산됨
        // 전체 호 길이를 라디안으로 변환
        let totalArcLength: Float = arcSpan * (.pi / 180)

        // 포인트 사이의 각도 계산 (각도를 균등하게 나누기)
        let angleStep = totalArcLength / Float(numPoints - 1)

        for i in 0..<numPoints {
            // 각도를 계산 (시계 또는 반시계 방향으로 회전)
            let angle = startAngle + (Float(i) * angleStep * (isRightSide ? 1 : -1))

            // 각도에 따라 x, z 좌표 계산
            let x = a * cos(angle)  // X축 대칭 (오른쪽은 양수, 왼쪽은 음수)
            let z = b * sin(angle)  // Z축 방향 (양수는 +Z, 음수는 -Z로 이동)

            // 최종 좌표 계산: 중심(centerPosition)을 기준으로 회전 적용
            let point = SIMD3<Float>(x + centerPosition.x, y, z + centerPosition.z)
            points.append(point)
        }

        return points
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
