//
//  CommitGraph.swift
//  hackprinceton
//
//  Created by Anthony Li on 3/29/24.
//

import Foundation

class CommitGraphNode {
    let sha: Sha
    let x: Int
    let z: Int
    var parents = [CommitGraphNode]()
    
    init(sha: Sha, x: Int, z: Int) {
        self.sha = sha
        self.x = x
        self.z = z
    }
}

extension CommitGraphNode: Identifiable {
    var id: Sha { sha }
}

func computeGraph(from repo: Repository) -> [CommitGraphNode] {
    var numEdges = repo.commits.mapValues { _ in 0 }
    for commit in repo.commits.values {
        for parent in commit.parent {
            if let existing = numEdges[parent] {
                numEdges[parent] = existing + 1
            } else {
                print("Warning: \(parent) not found!")
            }
        }
    }
    
    var s = Set(repo.commits.values.filter { numEdges[$0.sha]! == 0 })
    var sorted = [Commit]()
    
    while !s.isEmpty {
        let commit = s.removeFirst()
        sorted.append(commit)

        for parent in commit.parent {
            if let edges = numEdges[parent] {
                let newEdges = edges - 1
                numEdges[parent] = newEdges
                if newEdges == 0, let parentCommit = repo.commits[parent] {
                    s.insert(parentCommit)
                }
            }
        }
    }
    
    guard !sorted.isEmpty else {
        return []
    }
    
    var result = [CommitGraphNode]()
    var nodes = [Sha: CommitGraphNode]()
    var xValues = [Sha: Int]()
    var nextX = 0 // TODO: Make this less dumb
    
    for (i, commit) in sorted.enumerated() {
        let x: Int
        if let assignedX = xValues[commit.sha] {
            x = assignedX
        } else {
            // If we haven't already assigned our commit an X value, make a new one
            x = nextX
            nextX += 1
            xValues[commit.sha] = x
        }
        
        let node = CommitGraphNode(sha: commit.sha, x: x, z: i)
        result.append(node)
        nodes[commit.sha] = node
        
        if let firstParent = commit.parent.first, xValues[firstParent] == nil {
            // Assign the first parent to the same X value
            xValues[firstParent] = x
        }
    }
    
    for commit in sorted {
        nodes[commit.sha]!.parents.append(contentsOf: commit.parent.compactMap { nodes[$0] })
    }
    
    return result
}
