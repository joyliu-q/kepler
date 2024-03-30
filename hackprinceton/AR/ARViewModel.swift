//
//  ARViewModel.swift
//  hackprinceton
//
//  Created by Anthony Li on 3/30/24.
//

import SwiftUI
import RealityKit

let commitSphere = MeshResource.generateSphere(radius: 0.01)
let commitCollision = CollisionComponent(shapes: [.generateSphere(radius: 0.01)])

func createCommitEntity(for commit: Commit, color: UIColor) -> Entity {
    let entity = ModelEntity(mesh: commitSphere, materials: [SimpleMaterial(color: color, roughness: 0.5, isMetallic: true)])
    entity.components.set(commitCollision)
    entity.components.set(CommitComponent(commit: commit))
    return entity
}

func createCommitEntity(for commit: Commit) -> Entity {
    return createCommitEntity(for: commit, color: .systemRed)
}

let edgeBoxSize: Float = 0.002
let edgeBox = MeshResource.generateBox(size: edgeBoxSize)

func createEdgeEntity(color: UIColor) -> Entity {
    return ModelEntity(mesh: edgeBox, materials: [SimpleMaterial(color: color, roughness: 1.0, isMetallic: true)])
}

func placeCommits(from repo: Repository, in timelineRoot: Entity) {
    let xSpacing: Float = 0.03
    let y: Float = 0.015
    let zSpacing: Float = 0.03
    
    let nodes = computeGraph(from: repo)
    
    for node in nodes {
        guard let commit = repo.commits[node.sha] else { continue }
        
        let commitEntity = createCommitEntity(for: commit, color: node.color)
        commitEntity.position = SIMD3(x: Float(node.x) * xSpacing, y: y, z: -Float(node.z) * zSpacing)
        timelineRoot.addChild(commitEntity)
        
        for parent in node.parents {
            let newColor = if (node.parents.first?.color == node.color) {
                node.color
            } else {
                UIColor.white
            }
            let edgeEntity = createEdgeEntity(color: newColor)
            edgeEntity.position = SIMD3(
                x: (Float(node.x) + Float(parent.x)) / 2 * xSpacing,
                y: y,
                z: -(Float(node.z) + Float(parent.z)) / 2 * zSpacing
            )
            
            let xDiff = Float(node.x - parent.x) * xSpacing
            let zDiff = Float(parent.z - node.z) * zSpacing
            let length = sqrt(xDiff * xDiff + zDiff * zDiff)
            
            edgeEntity.scale = SIMD3(x: 1, y: 1, z: length / edgeBoxSize)
            
            let angle = atan(xDiff / zDiff)
            edgeEntity.orientation *= simd_quatf(angle: angle, axis: SIMD3(x: 0, y: 1, z: 0))
            timelineRoot.addChild(edgeEntity)
        }
    }
}

@Observable class ARViewModel {
    let rootEntity = Entity()
    var arView: ARView?
    
    func setup(repository: Repository, arView: ARView) {
        let timelineRoot = Entity()
        timelineRoot.name = "TimelineRoot"
        
        placeCommits(from: repository, in: timelineRoot)
        
        rootEntity.addChild(timelineRoot)
        
        self.arView = arView
    }
    
    func update(repository: Repository) {
        let timelineRoot = Entity()
        timelineRoot.name = "TimelineRoot"
        
        placeCommits(from: repository, in: timelineRoot)
        
        if let oldTimelineRoot = rootEntity.findEntity(named: "TimelineRoot") {
            oldTimelineRoot.removeFromParent()
            rootEntity.addChild(timelineRoot)
        }
    }
    
    func lookupCommit(at point: CGPoint) -> Commit? {
        guard let arView else { return nil }
        
        let results = arView.hitTest(point)
        if let result = results.first(where: { $0.entity.components.has(CommitComponent.self) }) {
            return result.entity.components[CommitComponent.self]!.commit
        }
        
        return nil
    }
}
