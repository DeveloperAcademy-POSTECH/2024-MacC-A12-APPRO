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
    let rightHandModelEntity = HandModelEntity()
    let leftHandModelEntity = HandModelEntity()
    
    var isFistShowing: Bool = false
    var isFirstPositioning: Bool = true
    var isRightDone: Bool = false
    var rightHandTransform = Transform()
    private(set) var numberOfObjects: Int = 8
    private var lastStarEntityTransform = Transform() //ShoulderTimer의 위치를 잡기 위한 변수
    
    
    
    func resetModelEntities() {
        modelEntities.forEach { entity in
            entity.removeFromParent()
        }
        modelEntities = []
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
    
    func addModelsToPoints(isRightSide: Bool, points: [SIMD3<Float>]) {
        let entityName = isRightSide ? "rightModelEntity" : "leftModelEntity"
        
        for (idx, point) in points.enumerated() {
            Task {
                if let starEntity = try? await Entity(named: "Shoulder/StarScene.usda", in: realityKitContentBundle) {
                    guard let starModelEntity = starEntity.findEntity(named: "Star") as? ModelEntity else { return }
                    starModelEntity.name = "\(entityName)-\(idx)"
                    starModelEntity.generateCollisionShapes(recursive: false)
                    
                    //TODO: 에셋자체를 회색으로 바꾸거나 UIColor로 디자인 색상 지정
                    let material = SimpleMaterial(color: .gray, isMetallic: false)
                    guard let mesh = starModelEntity.components[ModelComponent.self]?.mesh else {
                        debugPrint("no mesh found")
                        return
                    }
                    let modelComponent = ModelComponent(mesh: mesh, materials: [material])
                    starModelEntity.components.set(modelComponent)
                    
                    starModelEntity.name = "\(entityName)-\(idx)"
                    starModelEntity.position = point
                    starModelEntity.scale = SIMD3<Float>(repeating: 0.001)
                    
                    modelEntities.append(starModelEntity)
                    contentEntity.addChild(starModelEntity)
                    
                    // 마지막 인덱스 일때
                    if idx == numberOfObjects - 1 {
                        lastStarEntityTransform = starModelEntity.transform
                        let translation = lastStarEntityTransform.translation
                        
                        if isRightSide {
                            lastStarEntityTransform.translation = SIMD3<Float>(x: translation.x + 0.2, y: translation.y, z: translation.z + 0.1)
                            lastStarEntityTransform.rotation = simd_quatf(angle: .pi/2, axis: SIMD3<Float>(0, 1, 0))
                        } else {
                            lastStarEntityTransform.translation = SIMD3<Float>(x: translation.x - 0.2, y: translation.y, z: translation.z + 0.2)
                            lastStarEntityTransform.rotation = simd_quatf(angle: -.pi, axis: SIMD3<Float>(0, 1, 0))
                        }
                    }
                }
            }
        }
    }
    
    func createEntitiesOnEllipticalArc(handTransform: Transform) {
        // 손의 현재 위치를 파라미터로 받아서 어깨 기준으로 포물선을 계산 + 오른손보다 조금 옆으로 이동
        let rightHandTranslation = SIMD3<Float>(x: handTransform.translation.x + 0.05, y: handTransform.translation.y, z: handTransform.translation.z)
        // 원점과 handTranslation의 x축 차이에 따라 oppositeHandTranslation을 계산
        let leftHandTranslation = simd_float3(-rightHandTranslation.x, rightHandTranslation.y, rightHandTranslation.z)
        
        // 어깨 중심 위치 (어깨는 손의 위치에 맞추어 설정)
        let rightShoulderPosition = simd_float3(rightHandTranslation.x, rightHandTranslation.y, 0.0)
        let leftShoulderPosition = simd_float3(-rightShoulderPosition.x, rightHandTranslation.y, 0.0)
        
        // 손이 원점 기준으로 오른쪽에 있는지 왼쪽에 있는지에 따라 isRightSide를 결정
//        let isRightSide = handTranslation.x > 0
        
        if !isRightDone {
            // 오른쪽 손에 대한 포물선 경로 계산 (150도)
            let rightPoints = generateUniformEllipseArcPoints(
                centerPosition: rightShoulderPosition,
                numPoints: numberOfObjects,
                startPoint: rightHandTranslation,  // 오른쪽 손의 위치를 시작점으로 설정
                arcSpan: 150.0,
                isRightSide: true
            )
            
            addModelsToPoints(isRightSide: true, points: rightPoints)
        } else {
            // 왼쪽 손에 대한 포물선 경로 계산 (150도)
            let leftPoints = generateUniformEllipseArcPoints(
                centerPosition: leftShoulderPosition,  // 반대쪽 어깨 기준 위치
                numPoints: numberOfObjects,
                startPoint: leftHandTranslation,  // 반대쪽 손의 위치를 시작점으로 설정
                arcSpan: 150.0,
                isRightSide: false  // 왼손과 오른손 구분
            )
                        
            addModelsToPoints(isRightSide: false, points: leftPoints)
        }
    }
    
}
