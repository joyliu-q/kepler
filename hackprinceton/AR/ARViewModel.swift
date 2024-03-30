//
//  ARViewModel.swift
//  hackprinceton
//
//  Created by Anthony Li on 3/30/24.
//

import SwiftUI
import ARKit
import RealityKit

let edgeBoxSize: Float = 0.002
let edgeBox = MeshResource.generateBox(size: edgeBoxSize)

func createEdgeEntity(color: UIColor) -> Entity {
    return ModelEntity(mesh: edgeBox, materials: [SimpleMaterial(color: color, roughness: 1.0, isMetallic: true)])
}

@Observable class ARViewModel: NSObject {
    let rootEntity = Entity()
    var loadedEntity: Entity?
    
    #if os(iOS)
    var arView: ARView?
    var session: ARSession?
    
    var activeSha: Sha?
    
    @available(visionOS, unavailable) func attach(to arView: ARView) {
        self.arView = arView
        session = arView.session
    }
    #endif
    
    func createCommitEntity(for commit: Commit, color: UIColor, isActive: Bool = false) -> Entity {
        let entityName: String = isActive ? "Purple_Active" : "Purple_Inactive"
        
        if loadedEntity == nil {
            loadedEntity = try! Entity.load(named: "Scene", in: .main)
        }
        
        var entity = loadedEntity!.findEntity(named: entityName)!.clone(recursive: true)
        if !entity.children.isEmpty {
            entity = entity.children[0]
        }
            
        // Optionally customize the entity further if needed
        var material = entity.components[ModelComponent.self]!.materials[0] as! PhysicallyBasedMaterial
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
        
        let brighterColor = UIColor(hue: hue, saturation:  isActive ? 15: 0 + saturation, brightness: isActive ? 5: 0 + min(1, brightness + 0.2), alpha: 1)
        
        
        material.baseColor = .init(tint: brighterColor)
        material.emissiveColor = .init(color: color)
        
        entity.components[ModelComponent.self]!.materials = [material]
        
        // Remember to set your CommitComponent to keep commit data associated
        entity.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.02)]))
        entity.components.set(CommitComponent(commit: commit))
        
        #if os(visionOS)
        entity.components.set(InputTargetComponent())
        #endif
        
        return entity
    }
    
    func placeCommits(from repo: Repository, in timelineRoot: Entity) {
        let xSpacing: Float = 0.06
        let y: Float = 0.025
        let zSpacing: Float = 0.06
        
        let nodes = computeGraph(from: repo)
        
        for node in nodes {
            guard let commit = repo.commits[node.sha] else { continue }
            
            let commitEntity = createCommitEntity(for: commit, color: node.color, isActive: activeSha == node.sha)
            commitEntity.position = SIMD3(x: Float(node.x) * xSpacing, y: y, z: -Float(node.z) * zSpacing)
            timelineRoot.addChild(commitEntity)
            
            var nodeRed: CGFloat = 0
            var nodeGreen: CGFloat = 0
            var nodeBlue: CGFloat = 0
            node.color.getRed(&nodeRed, green: &nodeGreen, blue: &nodeBlue, alpha: nil)
            
            for parent in node.parents {
                var parentRed: CGFloat = 0
                var parentGreen: CGFloat = 0
                var parentBlue: CGFloat = 0
                parent.color.getRed(&parentRed, green: &parentGreen, blue: &parentBlue, alpha: nil)
                
                let gamma: CGFloat = 2
                let newColor = UIColor(
                    red: pow(pow(parentRed, gamma) + pow(nodeRed, gamma), 1 / gamma),
                    green: pow(pow(parentGreen, gamma) + pow(nodeGreen, gamma), 1 / gamma),
                    blue: pow(pow(parentBlue, gamma) + pow(nodeBlue, gamma), 1 / gamma),
                    alpha: 1
                )
                
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
    
    func setup(repository: Repository) {
        let timelineRoot = Entity()
        timelineRoot.name = "TimelineRoot"
        
        placeCommits(from: repository, in: timelineRoot)
        
        rootEntity.addChild(timelineRoot)
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
    
    #if os(iOS)
    func lookupCommit(at point: CGPoint) -> Commit? {
        guard let arView else { return nil }
        
        let results = arView.hitTest(point)
        if let result = results.first(where: { $0.entity.components.has(CommitComponent.self) }) {
            return result.entity.components[CommitComponent.self]!.commit
        }
        
        return nil
    }
    #endif
    
    var initialScale: Float?
    
    func handleScaleGestureChange(magnification: CGFloat) {
        if initialScale == nil {
            initialScale = rootEntity.scale.x
        }
        
        let newScale = Float(magnification) * initialScale!
        rootEntity.scale = SIMD3(x: newScale, y: newScale, z: newScale)
    }
    
    func handleScaleGestureEnd() {
        initialScale = nil
    }
}
