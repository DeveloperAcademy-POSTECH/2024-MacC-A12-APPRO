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
    let handModelEntity = HandModelEntity()
    var entryRocketEntity = Entity()
    var handRocketEntity = Entity()
    var shoulderTimerEntity = Entity()
    
    var isFistShowing: Bool = false
    var isFirstPositioning: Bool = true
    var isRightDone: Bool = false
    var isEntryEnd = false

    var rightHandTransform = Transform()
    var entryRocketTransForm = Transform()
    private var shoulderTimerPoint = SIMD3<Float>()

    // 별 모델 + 타이머
    private(set) var numberOfObjects: Int = 9
    private(set) var expectedNextNumber = 0
    private(set) var timerController: AnimationPlaybackController?
    

    
    deinit {
        dump("\(self) deinited")
        session.stop()
    }
    
    func resetExpectedNextNumber() {
        expectedNextNumber = 0
    }
    
    func addExpectedNextNumber() {
        expectedNextNumber += 1
    }
    
    func resetModelEntities() {
        modelEntities.forEach { entity in
            entity.removeFromParent()
        }
        modelEntities = []
    }
    
    func resetHandEntities() {
        handEntities.forEach { entity in
            entity.removeFromParent()
        }
        handEntities = []
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
                // 마지막 인덱스 일때
                if idx == numberOfObjects - 1 {
                    shoulderTimerPoint = point
                    return
                }
                
                if let starEntity = try? await Entity(named: "Shoulder/StarScene.usda", in: realityKitContentBundle) {
                    guard let starModelEntity = starEntity.findEntity(named: "Star") as? ModelEntity else { return }
                    
                    //TODO: 에셋자체를 회색으로 바꾸거나 UIColor로 디자인 색상 지정
                    let material = SimpleMaterial(color: .gray, isMetallic: false)
                    guard let mesh = starModelEntity.components[ModelComponent.self]?.mesh else {
                        debugPrint("no mesh found")
                        return
                    }
                    let modelComponent = ModelComponent(mesh: mesh, materials: [material])
                    starModelEntity.components.set(modelComponent)

                    starModelEntity.generateCollisionShapes(recursive: false)
                    starModelEntity.name = "\(entityName)-\(idx)"
                    starModelEntity.position = point
                    starModelEntity.scale = SIMD3<Float>(repeating: 0.001)
                    
                    modelEntities.append(starModelEntity)
                    contentEntity.addChild(starModelEntity)
                }
            }
        }
    }
    
    func createEntitiesOnEllipticalArc(handTransform: Transform) {
        resetExpectedNextNumber()
        // 손의 현재 위치를 파라미터로 받아서 어깨 기준으로 포물선을 계산 + 오른손보다 조금 옆으로 이동
        let rightHandTranslation = SIMD3<Float>(x: handTransform.translation.x + 0.1, y: handTransform.translation.y, z: handTransform.translation.z)
        // 원점과 handTranslation의 x축 차이에 따라 oppositeHandTranslation을 계산
        let leftHandTranslation = simd_float3(-rightHandTranslation.x, rightHandTranslation.y, rightHandTranslation.z)
        
        // 어깨 중심 위치 (어깨는 손의 위치에 맞추어 설정)
        let rightShoulderPosition = simd_float3(rightHandTranslation.x, rightHandTranslation.y, 0.0)
        let leftShoulderPosition = simd_float3(-rightShoulderPosition.x, rightHandTranslation.y, 0.0)
        
        if !isRightDone {
            let rightPoints = generateUniformEllipseArcPoints(
                centerPosition: rightShoulderPosition,
                numPoints: numberOfObjects,
                startPoint: rightHandTranslation,  // 오른쪽 손의 위치를 시작점으로 설정
                arcSpan: 180.0,
                isRightSide: true
            )
            
            addModelsToPoints(isRightSide: true, points: rightPoints)
        } else {
            let leftPoints = generateUniformEllipseArcPoints(
                centerPosition: leftShoulderPosition,  // 반대쪽 어깨 기준 위치
                numPoints: numberOfObjects,
                startPoint: leftHandTranslation,  // 반대쪽 손의 위치를 시작점으로 설정
                arcSpan: 180.0,
                isRightSide: false  // 왼손과 오른손 구분
            )
                        
            addModelsToPoints(isRightSide: false, points: leftPoints)
        }
    }
    
    func playAnimation(animationEntity: Entity) {
        for animation in animationEntity.availableAnimations {
            let animation = animation.repeat(count: 1)
            timerController = animationEntity.playAnimation(animation, transitionDuration: 0.0, startsPaused: false)
            break
        }
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
    
    func playSpatialAudio(_ entity: Entity) async {
        guard let audioEntity = entity.findEntity(named: "SpatialAudio"), let indexString = entity.name.split(separator: "-").last, let idx = Int(indexString) else { return }
        guard let resource = try? await AudioFileResource(named: "/Root/StarAudio_\((idx % 5) + 1)_wav",
                                                          from: "Shoulder/StarScene.usda",
                                                          in: realityKitContentBundle) else {
            debugPrint("audio not found")
            return
        }
        
        let audioPlayer = audioEntity.prepareAudio(resource)
        audioPlayer.play()
    }
    
    func changeMatreialColor(entity: Entity) {
        guard let modelEntity = entity as? ModelEntity else {
            debugPrint("not a model entity")
            return
        }
        
        // TODO: 불켜진 Star 모델 색상 변경
        let newMeterial = SimpleMaterial(color: .yellow, isMetallic: false)
        guard let mesh = modelEntity.components[ModelComponent.self]?.mesh else {
            debugPrint("no mesh found")
            return
        }
         
        let modelComponent = ModelComponent(mesh: mesh, materials: [newMeterial])
        modelEntity.components.set(modelComponent)
    }
    
    func addShoulderTimerEntity() {
        Task {
            if let rootEntity = try? await Entity(named: "Shoulder/ShoulderTimerScene.usda", in: realityKitContentBundle) {
                shoulderTimerEntity.name = "ShoulderTimerEntity"
                shoulderTimerEntity = rootEntity
                shoulderTimerEntity.position = shoulderTimerPoint
                // 스케일이 너무 큼
                shoulderTimerEntity.scale *= 0.1
                let angle = isRightDone ? -Float.pi/2 : -Float.pi/6
                shoulderTimerEntity.transform.rotation = simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
                
                var clearMaterial = PhysicallyBasedMaterial()
                clearMaterial.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(floatLiteral: 0))
                let collisionModelEntity = ModelEntity(mesh: .generateSphere(radius: 10), materials: [clearMaterial])
                collisionModelEntity.generateCollisionShapes(recursive: false)
                collisionModelEntity.name = "Timer"
             
                shoulderTimerEntity.addChild(collisionModelEntity)
                
                contentEntity.addChild(shoulderTimerEntity)
                modelEntities.append(shoulderTimerEntity)
            }
        }
    }
    
    func setEntryRocket() async {
        if let rootEntity = try? await Entity(named: "Shoulder/RocketScene.usda", in: realityKitContentBundle) {
            entryRocketEntity = rootEntity
            entryRocketEntity.name = "EntryRocket"
            entryRocketEntity.position = .init(x: 0, y: 1, z: -1)
            entryRocketEntity.transform.scale = .init(x: 0.1, y: 0.1, z: 0.1)
            entryRocketEntity.transform.rotation = .init(angle: .pi/2, axis: .init(x: 0, y: 1, z: 0))
            entryRocketTransForm = entryRocketEntity.transform
            contentEntity.addChild(entryRocketEntity)
        }
    }
    
    func playEntryRocketAnimation() {
        let goInDirection = FromToByAnimation<Transform> (
            name: "EntryRocket",
            from: entryRocketTransForm,
            to: rightHandTransform,
            duration: 2,
            bindTarget: .transform
        )
        
        do {
            let animation = try AnimationResource.generate(with: goInDirection)
            entryRocketEntity.playAnimation(animation, transitionDuration: 2)
        } catch {
            debugPrint("Error generating animation: \(error)")
        }
    }
    
    func setHandRocketEntity() {
        handRocketEntity = entryRocketEntity.clone(recursive: true)
        handRocketEntity.name = "rightHandRocket"
    }
}
