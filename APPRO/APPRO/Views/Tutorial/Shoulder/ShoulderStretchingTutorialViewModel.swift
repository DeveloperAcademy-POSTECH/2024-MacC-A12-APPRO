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
final class ShoulderStretchingTutorialViewModel {
    
    var tutorialManager: TutorialManager?
    
    var contentEntity = Entity()
    var modelEntities: [Entity] = []
    var handEntities: [Entity] = []
    
    let session = ARKitSession()
    var handTrackingProvider = HandTrackingProvider()
    var worldTrackingProvider = WorldTrackingProvider()
    var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    let handModelEntity = HandModelEntity()
    var entryRocketEntity = Entity()
    var handRocketEntity = Entity()
    var shoulderTimerEntity = Entity()
    private var starModelEntity: ModelEntity?
    
    var isFistShowing: Bool = false
    var isFirstPositioning: Bool = true
    var isRightDone: Bool = false
    var isEntryEnd = false

    var startingZ: Float = 0.0
    var rightHandTransform = Transform()
    var entryRocketTransForm = Transform()
    private var shoulderTimerPoint = SIMD3<Float>()

    // 별 모델 + 타이머
    private(set) var numberOfObjects: Int = 8
    private(set) var expectedNextNumber = 0
    private(set) var timerController: AnimationPlaybackController?
    
    let tutorialAttachmentViewID = "TutorialAttachmentView"

    var isTimerVisible = false
    var timerFiveProgressChecker : [Bool] = [true, true, true, true, true]
    
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
    
    func loadStarModelEntity() async {
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
            
            self.starModelEntity = starModelEntity
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
        let a: Float = b * 1.0  // 타원의 장축 반지름
        let y: Float = centerPosition.y  // Y 좌표는 어깨의 Y 좌표로 설정

        // startPoint와 centerPosition 사이의 벡터를 이용하여 startAngle 계산
        let deltaX = startPoint.x - centerPosition.x
        let deltaZ = startPoint.z - centerPosition.z
        // atan2를 사용하여 X, Z 평면에서의 각도(라디안)를 계산
        let startAngle = atan2(deltaZ, deltaX)  // 각도는 Z축을 기준으로 계산됨
        // 전체 호 길이를 라디안으로 변환
        let totalArcRadian: Float = arcSpan * (.pi / 180)

        // 포인트 사이의 각도 계산 (각도를 균등하게 나누기)
        let angleStep = totalArcRadian / Float(numPoints)

        for i in 0..<numPoints {
            // 각도를 계산 (시계 또는 반시계 방향으로 회전)
            let angle = i == numPoints - 1 ? startAngle + totalArcRadian : startAngle + (Float(i) * angleStep * (isRightSide ? 1 : -1))

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
        let entityName = "rightModelEntity"
        
        for (idx, point) in points.enumerated() {
                // 마지막 인덱스 일때
            if idx == numberOfObjects - 1  {
                    shoulderTimerPoint = point
                    return
                }
            guard let starModelEntity = self.starModelEntity?.clone(recursive: true) else { return }
                starModelEntity.name = "\(entityName)-\(idx)"
                starModelEntity.position = point
                starModelEntity.scale = SIMD3<Float>(repeating: 0.001)
                modelEntities.append(starModelEntity)
                contentEntity.addChild(starModelEntity)
        }
    }
    
    func createEntitiesOnEllipticalArc(handTransform: Transform) {
        resetExpectedNextNumber()
        let rightHandTranslation = SIMD3<Float>(x: handTransform.translation.x + 0.1, y: handTransform.translation.y, z: handTransform.translation.z)
        let rightShoulderPosition = simd_float3(rightHandTranslation.x, rightHandTranslation.y, startingZ)
        
        if !isRightDone {
            let rightPoints = generateUniformEllipseArcPoints(
                centerPosition: rightShoulderPosition,
                numPoints: numberOfObjects,
                startPoint: rightHandTranslation,  // 오른쪽 손의 위치를 시작점으로 설정
                arcSpan: 180.0,
                isRightSide: true
            )
            addModelsToPoints(isRightSide: true, points: rightPoints)
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
            if let rootEntity = try? await Entity(named: "Shoulder/ShoulderTimerScene_11.usda", in: realityKitContentBundle) {
                shoulderTimerEntity.name = "ShoulderTimerEntity"
                shoulderTimerEntity = rootEntity
                shoulderTimerEntity.position = shoulderTimerPoint
                // 스케일이 너무 큼
                shoulderTimerEntity.scale *= 0.1
                let angle = isRightDone ? -Float.pi/2 : -Float.pi/6
                shoulderTimerEntity.transform.rotation = simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
                
                var clearMaterial = PhysicallyBasedMaterial()
                clearMaterial.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(floatLiteral: 0))
                let collisionModelEntity = ModelEntity(mesh: .generateBox(width: 15, height: 50, depth: 15), materials: [clearMaterial])
                collisionModelEntity.generateCollisionShapes(recursive: false)
                collisionModelEntity.scale = .init(repeating: 0.1)
                collisionModelEntity.name = "Timer"
             
                shoulderTimerEntity.addChild(collisionModelEntity)
                
                contentEntity.addChild(shoulderTimerEntity)
                modelEntities.append(shoulderTimerEntity)
            }
        }
    }
    
    func setEntryRocket() async {
        if let rootEntity = try? await Entity(named: "Shoulder/RocketScene_New_Less.usda", in: realityKitContentBundle) { //TODO: RCP 콜리젼 크기 크게 하기
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
        handRocketEntity.name = "handRocket"
    }
    
    func addAttachmentView(_ content: RealityViewContent, _ attachments: RealityViewAttachments) {
        guard let tutorialAttachmentView = attachments.entity(for: tutorialAttachmentViewID) else {
            dump("TutorialAttachmentView not found in attachments!")
            return
        }
        tutorialAttachmentView.position = .init(x: -0.5, y: 1.6 , z: -1.3)
        content.add(tutorialAttachmentView)
    }
    
    func playCustomAnimation(timerEntity: Entity) {
        let targetModelEntities = ["b1", "b2", "b3", "b4", "b5"]
        var tasks: [Task<Void, Never>] = []
        
        for (index, target) in targetModelEntities.enumerated() {
            guard let modelEntity = timerEntity.findEntity(named: target) as? ModelEntity,
                  var modelComponent = modelEntity.components[ModelComponent.self] else { continue }
            guard let shaderGraphMaterial = modelComponent.materials as? [ShaderGraphMaterial] else { continue }
            
            var materialArray: [ShaderGraphMaterial] = []
            
            let task = Task {
                // 각 target의 index에 따라 1초씩 지연하여 시작 (0초, 1초, 2초, 3초, 4초)
                try? await Task.sleep(nanoseconds: UInt64(index) * 1_000_000_000)
                if Task.isCancelled { return }
                
                if timerFiveProgressChecker[index] {
                    for material in shaderGraphMaterial {
                        do {
                            var shaderMaterial = material
                            try shaderMaterial.setParameter(name: "PillarColor", value: .int(1))
                            materialArray.append(shaderMaterial)
                        } catch {
                            print("Failed to set parameter for PillarColor")
                        }
                    }
                    modelComponent.materials = materialArray
                    modelEntity.components.set(modelComponent)
                } else {
                    playBackProgressAnimation(index: index)
                    tasks.suffix(from: index).forEach { $0.cancel() }
                    return
                }
            }
            tasks.append(task)
        }
    }

    
    func playBackProgressAnimation ( index : Int) {
        let targetModelEntities = ["b1", "b2", "b3", "b4", "b5"]
        let timerEntity = self.shoulderTimerEntity
        
        if index == 0 {
            return
        } else {
            for i in stride(from: index, to: -1, by: -1) {
                guard let modelEntity = timerEntity.findEntity(named: targetModelEntities[i]) as? ModelEntity,
                      var modelComponent = modelEntity.components[ModelComponent.self] else { continue }
                guard let shaderGraphMaterial = modelComponent.materials as? [ShaderGraphMaterial] else { continue }
                Task {
                    var materialArray: [ShaderGraphMaterial] = []
                    
                    for material in shaderGraphMaterial {
                        do {
                            var shaderMaterial = material
                            try shaderMaterial.setParameter(name: "PillarColor", value: .int(0))
                            materialArray.append(shaderMaterial)
                        } catch {
                            print("Failed to set parameter for PillarColor")
                        }
                    }
                    
                    modelComponent.materials = materialArray
                    modelEntity.components.set(modelComponent)
                }
            }
        }
    }
    
    func stopAllTimerProgress() {
        timerFiveProgressChecker = timerFiveProgressChecker.map({ _ in false})
    }
    
    func initiateAllTimerProgress() {
        timerFiveProgressChecker = timerFiveProgressChecker.map({ _ in true})
    }

}
