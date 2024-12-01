    //
//  NeckStretchingView.swift
//  APPRO
//
//  Created by marty.academy on 11/28/24.
//

import SwiftUI
import RealityKit

struct NeckStretchingView: View {
    
    @State private var viewModel = NeckStretchingViewModel()
    
    @State private var areEntitiesAllLoaded = false
    
    @State private var stretchingPhase: NeckStretchingPhase = .waiting
    
    @State private var waitingConfigurationDone : Bool = false
    
    var body: some View {
        RealityView { content, attachments in
            viewModel.addStretchingAttachmentView(attachments)
            
        } update: { content, attachments in
            if areEntitiesAllLoaded {
                configure(content: content, phase: stretchingPhase)
                viewModel.addCoinEntity(content)
            }
        } attachments: {
            Attachment(id: viewModel.stretchingAttachmentViewID) {
                StretchingAttachmentView(counter: viewModel, stretchingPart: .neck)
            }
        }
        .task {
            do {
                try await viewModel.loadEntities()
                areEntitiesAllLoaded = true
            } catch {
                areEntitiesAllLoaded = false
            }
        }
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { tapEvent in
                    // Pig's the most exterior-close model entity name : ______  FIXME: fix entity name ____ to more semantic way
                    if tapEvent.entity.name == "______" {
                        if viewModel.coinEntities.count == 0 {
                            viewModel.makeSemiCircleWithCoins()
                        } else {
                            viewModel.resetCoins() // 여기서 stretchingPhase를 변경하는 구문을 출력하면 resetCoins 가 제대로 작동하지 않는다. 위는 잘 작동한다. 왜 ??
                        }
                    }
                }
        )
        .onChange(of: viewModel.coinEntities, initial: false) { _, newValue in }
        .onChange(of: viewModel.completionStatusArray, initial: false ) { _, newStatusArray in
            if newStatusArray.allSatisfy({$0 == true}) {
                if viewModel.direction == .vertical {
                    viewModel.direction = .horizontal
                    viewModel.resetCoins(currentLocationBased: false)
                    
                } else {
                    viewModel.direction = .vertical
                    viewModel.resetCoins(currentLocationBased: false)
                }
                
                for i in 0...1 {
                    if viewModel.twoWayStretchingCompletionStatus[i] == false {
                        viewModel.twoWayStretchingCompletionStatus[i] = true
                        break
                    }
                }
                
//                let index: Int = viewModel.twoWayStretchingCompletionStatus.first(where: {$0 == false})
//                viewModel.twoWayStretchingCompletionStatus[index] = true
                
                viewModel.completionStatusArray = [false, false]
                viewModel.collisionBound.setZeroForBothBounds()
                
                
            }
        }
        .onChange(of: viewModel.twoWayStretchingCompletionStatus, initial: false) { _, newStatus in
            if newStatus.allSatisfy({$0 == true}) {
                viewModel.doneCount += 1
                viewModel.twoWayStretchingCompletionStatus = [false, false]
                viewModel.collisionBound.setZeroForBothBounds()
            }
        }
        .onChange(of: viewModel.doneCount, initial: false) { oldValue, newValue in
            if newValue == viewModel.maxCount {
                stretchingPhase = .finished
            }
            
            if newValue == 0 && oldValue > newValue {
                stretchingPhase = .stretching
                viewModel.enableAllCoins()
            }
        }
    }
}

private extension NeckStretchingView {
    
    func configure(content: RealityViewContent, phase: NeckStretchingPhase) {
        switch phase {
        case .waiting :
            if !waitingConfigurationDone {
                viewModel.configureInitialSettingToPig()
                viewModel.adjustAttachmentViewLocation(content)
                content.add(viewModel.pigEntity)
                viewModel.configureDeviceTrackingToPigEntity()
                viewModel.subscribePigCollisionEvent(content)
                
                DispatchQueue.main.async {
                    waitingConfigurationDone = true
                    stretchingPhase = .stretching
                }
            }
            
        case .stretching : break
            
        case .finished :
            viewModel.disableAllCoins()
        }
    }
}
