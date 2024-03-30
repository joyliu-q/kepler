//
//  CommitGraph.swift
//  hackprinceton
//
//  Created by Anthony Li on 3/29/24.
//

import Foundation

struct CommitGraphNode {
    let sha: Sha
    var x: Int
    var z: Int
}

func computeGraph(from repo: Repository) {
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
    
    var s = 
    var sorted = [Commit]()
    
    // First, narrow down to orphans
    for commit in repo.commits.values {
        s.subtract(commit.parent)
    }
    
    while !s.isEmpty {
        let sha = s.removeFirst()
        guard let commit = repo.commits[sha] else {
            print("Warning: \(sha) not found!")
            continue
        }
        
        
    }
}
