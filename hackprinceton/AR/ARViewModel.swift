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

@MainActor class ARViewModel: NSObject, ObservableObject {
    let xSpacing: Float = 0.06
    let y: Float = 0.025
    let yBranchLabel: Float = 0.07
    let yDetail: Float = 0.15
    let zSpacing: Float = 0.06
        
    let rootEntity: Entity = {
        let entity = Entity()
        entity.components.set(ExpansionComponent(state: .notExpanded))
        return entity
    }()
    var loadedEntity: Entity?
    @Published var selectedCommit: Commit? {
        didSet {
            if selectedCommit != nil, isExpanded {
                #if os(visionOS)
                focusSelectedCommit(preserveInitialPosition: true)
                #endif
            }
        }
    }
    var attachment: Entity?
    
    var lastKnownSelectedCommit: Commit?
    var lastKnownRepositoryState: Repository?
    var lastKnownExpanded: Bool?
    var nodesDict: [Sha: CommitGraphNode]?
    
    @Published var isExpanded = false
    
    #if os(iOS)
    var arView: ARView?
    var session: ARSession?
        
    @available(visionOS, unavailable) func attach(to arView: ARView) {
        self.arView = arView
        session = arView.session
    }
    #else
    let anchorEntity = AnchorEntity(.head)
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
        
        let brighterColor = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: isExpanded ? 0.6 : 1)
        
        material.baseColor = .init(tint: brighterColor)
        material.emissiveColor = .init(color: isActive ? .white : color.withAlphaComponent(isExpanded ? 0.6 : 1))
        
        entity.components[ModelComponent.self]!.materials = [material]
        
        // Remember to set your CommitComponent to keep commit data associated
        if isExpanded {
            entity.components.remove(CollisionComponent.self)
        } else {
            entity.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.02)]))
            #if os(visionOS)
            entity.components.set(InputTargetComponent())
            entity.components.set(HoverEffectComponent())
            #endif
        }
        
        entity.components.set(CommitComponent(commit: commit))
        
        return entity
    }
    
    func placeCommits(from repo: Repository) -> Entity? {
        guard repo != lastKnownRepositoryState || selectedCommit != lastKnownSelectedCommit || lastKnownExpanded != isExpanded else { return nil }
        logger.warning("Updating commits. Timestamp is \(Date().timeIntervalSince1970)")
        
        let timelineRoot = Entity()
        timelineRoot.name = "TimelineRoot"
        
        let (nodes, nodesDict) = computeGraph(from: repo)
        
        for node in nodes {
            guard let commit = repo.commits[node.sha] else { continue }
            
            let commitEntity = createCommitEntity(for: commit, color: node.color, isActive: selectedCommit?.sha == node.sha)
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
        
        var heads = [Sha: [String]]()
        for branch in repo.branches {
            if repo.commits[branch.head] != nil {
                var branches = heads[branch.head, default: []]
                branches.append(branch.name)
                heads[branch.head] = branches
            }
        }
        
        for (head, branches) in heads {
            guard let node = nodesDict[head] else { continue }
            let names = branches.joined(separator: ", ")
            
            if let branchEntity = BranchLabelRenderer.shared.renderBranchLabel(for: names, color: node.color) {
                branchEntity.position = SIMD3(x: Float(node.x) * xSpacing, y: yBranchLabel, z: -Float(node.z) * zSpacing)
                timelineRoot.addChild(branchEntity)
            }
        }
        
        self.nodesDict = nodesDict
        self.lastKnownRepositoryState = repo
        self.lastKnownSelectedCommit = selectedCommit
        self.lastKnownExpanded = isExpanded
        
        return timelineRoot
    }
    
    func placeAttachment(in attachmentRoot: Entity) {
        let resolvedAttachment: Entity?
        if let selectedCommit, let node = nodesDict?[selectedCommit.sha], let attachment, !isExpanded {
            resolvedAttachment = attachment
            attachment.position = SIMD3(x: Float(node.x) * xSpacing, y: yDetail, z: -Float(node.z) * zSpacing + 0.002)
        } else {
            resolvedAttachment = nil
        }
        
        if let child = attachmentRoot.children.first, child != resolvedAttachment {
            attachmentRoot.removeChild(attachmentRoot.children[0])
        }
        
        if attachmentRoot.children.isEmpty, let resolvedAttachment {
            attachmentRoot.addChild(resolvedAttachment)
        }
    }
    
    func setup(repository: Repository) {
        if let timelineRoot = placeCommits(from: repository) {
            rootEntity.addChild(timelineRoot)
        }
        
        let attachmentRoot = Entity()
        attachmentRoot.name = "AttachmentRoot"
        placeAttachment(in: attachmentRoot)
        rootEntity.addChild(attachmentRoot)
    }
    
    func update(repository: Repository) {
        if let timelineRoot = placeCommits(from: repository) {
            rootEntity.findEntity(named: "TimelineRoot")?.removeFromParent()
            rootEntity.addChild(timelineRoot)
        }

        if let attachmentRoot = rootEntity.findEntity(named: "AttachmentRoot") {
            placeAttachment(in: attachmentRoot)
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
        guard !isExpanded else { return }
        guard rootEntity.components[ExpansionComponent.self]!.state == .notExpanded else { return }
        
        if initialScale == nil {
            initialScale = rootEntity.scale.x
        }
        
        let newScale = Float(magnification) * initialScale!
        rootEntity.scale = SIMD3(x: newScale, y: newScale, z: newScale)
    }
    
    func handleScaleGestureChange(magnification: CGFloat, relativeTo anchorEntity: Entity) {
        guard !isExpanded else { return }
        guard rootEntity.components[ExpansionComponent.self]!.state == .notExpanded else { return }
        
        if initialScale == nil {
            initialScale = rootEntity.scale.x
        }
        
        let newScale = Float(magnification) * initialScale!
        let newPosition = anchorEntity.position(relativeTo: nil) - newScale * anchorEntity.position
        rootEntity.position = newPosition
        rootEntity.scale = SIMD3(x: newScale, y: newScale, z: newScale)
    }
    
    func handleScaleGestureEnd() {
        initialScale = nil
    }
    
    #if os(iOS)
    var initialPosition: SIMD3<Float>?
    var initialProjection: SIMD3<Float>?
    
    func handlePhoneDragGestureChange(location: CGPoint) {
        if initialPosition == nil {
            initialPosition = rootEntity.position
        }
        
        guard let arView else { return }
        
        let projection = arView.unproject(location, ontoPlane: rootEntity.transform.matrix, relativeToCamera: false)
        print("Projected \(location) onto \(projection)")
        guard let projection else { return }
        
        if initialProjection == nil {
            initialProjection = projection
        }
                
        rootEntity.position = initialPosition! + (projection - initialProjection!)
    }
    
    func handlePhoneDragGestureEnd() {
        initialPosition = nil
    }
    #endif
    
    #if os(visionOS)
    func expand() {
        handleScaleGestureEnd()
        isExpanded = true
        focusSelectedCommit(preserveInitialPosition: false)
    }
    
    func focusSelectedCommit(preserveInitialPosition: Bool) {
        var i_p = rootEntity.position
        var i_s = rootEntity.scale
        
        if preserveInitialPosition {
            switch rootEntity.components[ExpansionComponent.self]!.state {
            case .expansionQueued(let initialPosition, let initialScale, _, _):
                i_p = initialPosition
                i_s = initialScale
            case .shrinkQueued(let initialPosition, let initialScale):
                i_p = initialPosition
                i_s = initialScale
            case .animating(let initialPosition, let initialScale, _, _, _, _, _, _):
                i_p = initialPosition
                i_s = initialScale
            default:
                break
            }
        }
        
        guard let commit = selectedCommit, let node = nodesDict?[commit.sha] else { return }
        
        let desiredAnchorPoint = SIMD3(x: Float(node.x) * xSpacing, y: y, z: -Float(node.z) * zSpacing)
        let desiredScale = SIMD3<Float>(60, 60, 60)
        let headPosition = anchorEntity.position + SIMD3<Float>(0, 1.5, 0)
        rootEntity.components[ExpansionComponent.self]!.state = .expansionQueued(initialPosition: i_p, initialScale: i_s, desiredPosition: headPosition - desiredAnchorPoint * desiredScale, desiredScale: desiredScale)
    }
    
    func shrink() {
        isExpanded = false
        
        let i_p: SIMD3<Float>
        let i_s: SIMD3<Float>
        
        switch rootEntity.components[ExpansionComponent.self]!.state {
        case .expansionQueued(let initialPosition, let initialScale, _, _):
            i_p = initialPosition
            i_s = initialScale
        case .shrinkQueued(let initialPosition, let initialScale):
            i_p = initialPosition
            i_s = initialScale
        case .animating(let initialPosition, let initialScale, _, _, _, _, _, _):
            i_p = initialPosition
            i_s = initialScale
        default:
            return
        }
        
        rootEntity.components[ExpansionComponent.self]!.state = .shrinkQueued(initialPosition: i_p, initialScale: i_s)
    }
    
    var initialPosition: SIMD3<Float>?
    
    func handleDragGestureChange(translation: Vector3D) {
        guard !isExpanded else { return }
        guard rootEntity.components[ExpansionComponent.self]!.state == .notExpanded else { return }
        
        if initialPosition == nil {
            initialPosition = rootEntity.position
        }
        
        rootEntity.position = initialPosition! + SIMD3(x: Float(translation.x), y: Float(translation.y), z: Float(translation.z)) * 0.1 / 400
    }
    
    func handleDragGestureEnd() {
        initialPosition = nil
    }
    #endif
}
