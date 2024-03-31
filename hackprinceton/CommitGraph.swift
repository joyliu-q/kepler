//
//  CommitGraph.swift
//  hackprinceton
//
//  Created by Anthony Li on 3/29/24.
//

import Foundation
import UIKit

let VALID_COLORS: [UIColor] = [
    .systemPink,
    .systemBlue,
    .systemPurple,
    .systemMint,
    .systemTeal,
    .systemCyan
]

class CommitGraphNode {
    let sha: Sha
    let x: Int
    let z: Int
    let color: UIColor
    var parents = [CommitGraphNode]()
    
    init(sha: Sha, x: Int, z: Int, color: UIColor) {
        self.sha = sha
        self.x = x
        self.z = z
        self.color = color
    }
    
}

extension CommitGraphNode: Identifiable {
    var id: Sha { sha }
}

func computeGraph(from repo: Repository) -> ([CommitGraphNode], [Sha: CommitGraphNode]) {
    var numEdges = repo.commits.mapValues { _ in 0 }
    for commit in repo.commits.values {
        for parent in commit.parent {
            if let existing = numEdges[parent] {
                numEdges[parent] = existing + 1
            }
        }
    }
    
    var s = repo.commits.values.filter { numEdges[$0.sha]! == 0 }
    var sorted = [Commit]()
    
    while !s.isEmpty {
        let commit = s.removeLast()
        sorted.append(commit)

        for parent in commit.parent {
            if let edges = numEdges[parent] {
                let newEdges = edges - 1
                numEdges[parent] = newEdges
                if newEdges == 0, let parentCommit = repo.commits[parent] {
                    s.append(parentCommit)
                }
            }
        }
    }
    
    guard !sorted.isEmpty else {
        return ([], [:])
    }
    
    var result = [CommitGraphNode]()
    var nodes = [Sha: CommitGraphNode]()
    var xValues = [Sha: Int]()
    var nextXLeft = -1
    var nextXRight = 0
    
    var nodeColors = [Sha: UIColor]()
    for commit in sorted.reversed() {
        let parents = commit.parent.filter({c in
            repo.commits.keys.contains(c)
        })
        if parents.count > 1 || parents.count == 0 {
            var hasher = Hasher()
            hasher.combine(commit.sha)
            nodeColors[commit.sha] = VALID_COLORS[(hasher.finalize() % VALID_COLORS.count + VALID_COLORS.count) % VALID_COLORS.count]
        } else {
            nodeColors[commit.sha] = nodeColors[parents.first!]!
        }
    }
    
    for (i, commit) in sorted.enumerated() {
        let x: Int
        if let assignedX = xValues[commit.sha] {
            x = assignedX
        } else {
            // If we haven't already assigned our commit an X value, make a new one
            x = nextXRight
            nextXRight += 1
            xValues[commit.sha] = x
        }
        
        let node = CommitGraphNode(sha: commit.sha, x: x, z: i, color: nodeColors[commit.sha]!)
        result.append(node)
        nodes[commit.sha] = node
        
        if let firstParent = commit.parent.first {
            // Assign the first parent to the same X value
            if xValues[firstParent] == nil {
                xValues[firstParent] = x
            }
            
            // Attempt to assign remaining parents to X values such that the graph is visually balanced
            for parent in commit.parent.dropFirst() {
                if xValues[parent] == nil {
                    let leftDistance = x - nextXLeft
                    let rightDistance = nextXRight - x
                    
                    let newX: Int
                    if leftDistance < rightDistance {
                        newX = nextXLeft
                        nextXLeft -= 1
                    } else {
                        newX = nextXRight
                        nextXRight += 1
                    }
                    
                    xValues[parent] = newX
                }
            }
        }
    }
    
    for commit in sorted {
        nodes[commit.sha]!.parents.append(contentsOf: commit.parent.compactMap { nodes[$0] })
    }
    
    return (result, nodes)
}
