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
let commitMaterial = SimpleMaterial(color: .systemBlue, roughness: 0.5, isMetallic: true)

func createCommitEntity(for commit: Commit) -> Entity {
    let entity = ModelEntity(mesh: commitSphere, materials: [commitMaterial])
    entity.components.set(commitCollision)
    entity.components.set(CommitComponent(commit: commit))
    return entity
}

func placeCommits(from repo: Repository, in timelineRoot: Entity) {
    let nodes = computeGraph(from: repo)
    for node in nodes {
        guard let commit = repo.commits[node.sha] else { continue }
        
        let commitEntity = createCommitEntity(for: commit)
        commitEntity.position = SIMD3(x: Float(node.x) * 0.03, y: 0.015, z: Float(node.z) * 0.03)
        timelineRoot.addChild(commitEntity)
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
