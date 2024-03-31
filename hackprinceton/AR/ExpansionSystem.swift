//
//  ExpansionSystem.swift
//  hackprinceton
//
//  Created by Anthony Li on 3/30/24.
//

import Foundation
import RealityKit

struct ExpansionComponent: Component {
    var state: State
    
    indirect enum State: Equatable {
        case notExpanded
        case expansionQueued(initialPosition: SIMD3<Float>, initialScale: SIMD3<Float>, desiredPosition: SIMD3<Float>, desiredScale: SIMD3<Float>)
        case shrinkQueued(initialPosition: SIMD3<Float>, initialScale: SIMD3<Float>)
        case animating(initialPosition: SIMD3<Float>, initialScale: SIMD3<Float>, startPosition: SIMD3<Float>, startScale: SIMD3<Float>, endPosition: SIMD3<Float>, endScale: SIMD3<Float>, time: TimeInterval, targetState: State?)
    }
}

class ExpansionSystem: System {
    required init(scene: Scene) {}
    
    func update(context: SceneUpdateContext) {
        let entities = context.entities(matching: .init(where: .has(ExpansionComponent.self)), updatingSystemWhen: .rendering)
        for entity in entities {
            switch entity.components[ExpansionComponent.self]!.state {
            case .expansionQueued(let initialPosition, let initialScale, let desiredPosition, let desiredScale):
                entity.components[ExpansionComponent.self]!.state = .animating(initialPosition: initialPosition, initialScale: initialScale, startPosition: entity.position, startScale: entity.scale, endPosition: desiredPosition, endScale: desiredScale, time: 0, targetState: nil)
            case .shrinkQueued(let initialPosition, let initialScale):
                entity.components[ExpansionComponent.self]!.state = .animating(initialPosition: initialPosition, initialScale: initialScale, startPosition: entity.position, startScale: entity.scale, endPosition: initialPosition, endScale: initialScale, time: 0, targetState: .notExpanded)
            case .animating(let initialPosition, let initialScale, let startPosition, let startScale, let endPosition, let endScale, let time, let targetState):
                let newTime = min(time + context.deltaTime, 1)
                let position = startPosition * Float(1 - newTime) + endPosition * Float(newTime)
                let scale = startScale * Float(1 - newTime) + endScale * Float(newTime)
                
                entity.position = position
                entity.scale = scale
                
                if newTime >= 1, let targetState {
                    entity.components[ExpansionComponent.self]!.state = targetState
                } else {
                    entity.components[ExpansionComponent.self]!.state = .animating(initialPosition: initialPosition, initialScale: initialScale, startPosition: startPosition, startScale: startScale, endPosition: endPosition, endScale: endScale, time: newTime, targetState: targetState)
                }
            default:
                break
            }
        }
    }
}
