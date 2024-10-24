//
//  ShoulderStretchingViewModel.swift
//  APPRO
//
//  Created by 정상윤 on 10/20/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

@Observable
@MainActor
final class ShoulderStretchingViewModel {
    
    var contentEntity = Entity()
    var childrenEntities: [Entity] = []
    
    let session = ARKitSession()
    var handTrackingProvider = HandTrackingProvider()
    var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    
    var rightThumbIntermediateBaseModelEntity = ModelEntity.createHandEntity(number: 3)
    var rightIndexFingerTipModelEntity = ModelEntity.createHandEntity(number: 10)
    var rightMiddleFingerKnuckleModelEntity = ModelEntity.createHandEntity(isWrist: true, number: 12)
    
    var isFistShowing: Bool = false
    var animationControllerList = [AnimationPlaybackController]()
    var isEntityAdded: Bool = false
    
    init() {
        Task {
            guard HandTrackingProvider.isSupported else {
                dump("HandTrackingProvider is not supported")
                return
            }
            do {
                try await session.run([handTrackingProvider])
            } catch {
                dump(error)
            }
        }
    }
    
    deinit {
        dump("\(self) deinited")
        session.stop()
    }
    
    //MARK: ARC
    // 엔터티 생성 및 배치 함수
    func createEntitiesOnEllipticalArc(handTransform: Transform) {
        
        // 손의 현재 위치를 파라미터로 받아서 어깨 기준으로 포물선을 계산
        let handTranslation = handTransform.translation
        
        // 어깨 중심 위치 (어깨는 (0.5, 0, 0)에 있다고 가정)
        let shoulderPosition = simd_float3(0.1, handTranslation.y, 0.0)
        
        // 어깨 중심을 기준으로 회전 각도를 계산
        var rotationAngle = calculateRotationAngle(from: handTranslation - shoulderPosition)
        rotationAngle -= 0.1
        // 어깨 중심을 기준으로 포물선의 경로를 계산
        let points = generateUniformEllipseArcPoints(
            shoulderPosition: shoulderPosition,
            handTranslation: handTranslation,
            numPoints: 7,
            rotationAngle: rotationAngle
        )
        // 포물선 상의 점들을 생성하고 회전 적용
        for (idx, point) in points.enumerated() {
            Task {
                if let animationEntity = try? await Entity(named: "StarScene.usda", in: realityKitContentBundle) {
                    guard let rootEntity1 = animationEntity.findEntity(named: "Star"), let starModelEntity = rootEntity1 as? ModelEntity else { return }
                    starModelEntity.physicsBody = PhysicsBodyComponent()
                    starModelEntity.physicsBody?.isAffectedByGravity = false
                    starModelEntity.physicsBody?.isTranslationLocked = (true, true, true)
                    starModelEntity.physicsBody?.massProperties.mass = 100
                    starModelEntity.name = "animationEntity-\(idx)"
                    starModelEntity.generateCollisionShapes(recursive: false)
                    
                    animationEntity.name = "animationEntity-\(idx)"
                    animationEntity.position = point
                    animationEntity.scale = SIMD3<Float>(repeating: 0.03)
                    childrenEntities.append(animationEntity)
                    contentEntity.addChild(animationEntity)
                }
            }
        }
        isEntityAdded = true
    }
    
    // 타원의 호 길이에 따라 일정한 간격으로 좌표를 생성하는 함수
    // 어깨 중심을 기준으로 포물선 경로의 좌표를 생성하는 함수
    func generateUniformEllipseArcPoints(shoulderPosition: SIMD3<Float>, handTranslation: SIMD3<Float>, numPoints: Int, rotationAngle: Float) -> [SIMD3<Float>] {
        var points: [SIMD3<Float>] = []
        let arcRadius = simd_distance(shoulderPosition, handTranslation)
        //        debugPrint("반지름", arcRadius)
        // 타원의 단축 반지름(b) 및 장축 반지름(a) 설정
        let b: Float = arcRadius > 0.4 ? arcRadius : 0.4  // 타원의 단축 반지름
        let a: Float = arcRadius > 0.4 ? arcRadius * 1.4 : 0.6 // 타원의 장축 반지름
        let y: Float = handTranslation.y
        let initX: Float = 0
        
        // 호의 길이를 일정하게 나누기 위해 각도를 더 자주 계산
        let samples = 1000  // 더 많은 샘플을 사용할수록 정확도가 높아짐
        var cumulativeDistance: [Float] = [0.0]
        
        // 시작점의 위치를 어깨 중심을 반영하여 초기화
        var previousPoint = SIMD3<Float>(initX, y, -b)
        
        for i in 1...samples {
            let theta = Float(i) * (Float.pi * 2 / 3) / Float(samples)
            let x = a * sin(theta) + initX  // x 좌표에 handTranslation.x 적용
            let z = b * cos(theta)
            let currentPoint = SIMD3<Float>(x, y, -z)
            
            // 현재 포인트와 이전 포인트 사이의 거리를 계산
            let distance = simd_distance(currentPoint, previousPoint)
            cumulativeDistance.append(cumulativeDistance.last! + distance)
            previousPoint = currentPoint
        }
        
        // 타원의 전체 길이
        let totalLength = cumulativeDistance.last!
        
        // 일정한 간격으로 배치할 타겟 간격
        let segmentLength = totalLength / Float(numPoints - 1)
        
        // 일정한 간격으로 포인트 선택
        var currentSegmentLength: Float = 0
        for i in 1..<cumulativeDistance.count {
            if cumulativeDistance[i] >= currentSegmentLength {
                let theta = Float(i) * (Float.pi * 2 / 3) / Float(samples)
                let x = a * sin(theta) + initX  // x 좌표에 handTranslation.x 적용
                let z = b * cos(theta)
                var point = SIMD3<Float>(x, y, -z)
                
                // 어깨 중심을 기준으로 회전 행렬 적용
                point = rotate(point: point, angle: rotationAngle, axis: SIMD3<Float>(0.1, 1, 0))
                points.append(point)
                
                // 다음 세그먼트 길이로 이동
                currentSegmentLength += segmentLength
            }
        }
        
        return points
    }
    
    // 회전 행렬을 적용하여 회전된 좌표를 반환하는 함수
    func rotate(point: simd_float3, angle: Float, axis: simd_float3) -> simd_float3 {
        let rotationMatrix = simd_float3x3(rotationAngle: angle, axis: axis)
        return rotationMatrix * point
    }
    
    
    func playAnimation(animationEntity: Entity) {
        for animation in animationEntity.availableAnimations {
            let animation = animation.repeat(count: 1)
            let animationName = animation.name ?? "Unnamed animation"
            debugPrint("Found animation \(animationName) on \(animationEntity.name)")
            if animationName == "default subtree animation" {
                let controller = animationEntity.playAnimation(animation, transitionDuration: 0.0, startsPaused: true)
                controller.speed = 0.5
                self.animationControllerList.append(controller)
            }
        }
        animationControllerList.last?.resume()
    }
    
    func playEmitter(eventEntity: Entity) {
        guard let particleEntity = eventEntity.findEntity(named: "ParticleEmitter"), var particleEmitterComponent = particleEntity.components[ParticleEmitterComponent.self] else {
            debugPrint("particle Emitter component not found")
            return
        }
        eventEntity.components.remove(ParticleEmitterComponent.self)
        particleEmitterComponent.isEmitting = true
        particleEmitterComponent.simulationState = .stop
        particleEmitterComponent.simulationState = .play
        
        eventEntity.components.set([particleEmitterComponent])
    }
    
    func playSpatialAudio(_ entity: Entity) async throws {
        guard let audioEntity = entity.findEntity(named: "SpatialAudio"), let indexString = entity.name.split(separator: "-").last, let idx = Int(indexString) else { return }
        guard let resource = try? await AudioFileResource(named: "/Root/StarAudio_\((idx % 5) + 1)_wav",
                                                          from: "StarScene.usda",
                                                          in: realityKitContentBundle) else {
            debugPrint("오디오 not found")
            return
        }
        
        let audioPlayer = audioEntity.prepareAudio(resource)
        audioPlayer.play()
        
    }
    
    
    func resetChildEntities() {
        childrenEntities.forEach { entity in
            entity.removeFromParent()
        }
        childrenEntities = []
        isEntityAdded = false
    }
    
    func calculateRotationAngle(from translation: simd_float3) -> Float {
        // 0.0.0 오리진에서의 기준 벡터: -Z축을 기준으로 계산
        let originVector = simd_float3(0, 0, -1)  // -Z축 벡터
        let targetVector = simd_normalize(translation)  // translation 벡터를 정규화
        
        // 벡터의 내적을 이용하여 각도를 계산
        let dotProduct = simd_dot(originVector, targetVector)
        
        // 내적의 역코사인을 사용하여 벡터 간의 각도 계산 (라디안 값 반환)
        let clampedDotProduct = max(min(dotProduct, 1.0), -1.0)  // acos 함수의 입력값을 [-1, 1]로 제한
        let angle = acos(clampedDotProduct)  // 내적의 역코사인 값
        
        // 각도를 반환 (라디안 단위)
        return angle
    }
}
