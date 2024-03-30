//
//  GeneralARStuff.swift
//  hackprinceton
//
//  Created by Anthony Li on 3/30/24.
//

import RealityKit

func setupScene(repository: Repository, rootEntity: Entity) {
    let timelineRoot = Entity()
    timelineRoot.name = "TimelineRoot"
    
    placeCommits(from: repository, in: timelineRoot)
    
    rootEntity.addChild(timelineRoot)
}

func updateScene(repository: Repository, rootEntity: Entity) {
    let timelineRoot = Entity()
    timelineRoot.name = "TimelineRoot"
    
    placeCommits(from: repository, in: timelineRoot)
    
    if let oldTimelineRoot = rootEntity.findEntity(named: "TimelineRoot") {
        oldTimelineRoot.removeFromParent()
        rootEntity.addChild(timelineRoot)
    }
}

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
