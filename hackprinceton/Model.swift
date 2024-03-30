//
//  Model.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/29/24.
//

import Foundation

typealias Sha = String

struct Commit: Equatable, Hashable {
    var sha: Sha
    var parent: [Commit]
    
    var author: String     // TODO: do not support co-authors right now, as well as different authors and committers
    var title: String
    var description: String?
    
    // Displays
    //    var diff: String? // For now, potentially not possible
    
    // Optional metadata fields
    //    var verified: Bool
    
}

struct Branch: Hashable {
    var head: Sha
    var name: String
}

struct Repository {
    var url: String
    var branches: [Branch]
    var commits: Dictionary<Sha, Commit>
    
    var main: String = "main"
    
    /// Get HEAD commit from the main branch
    func getHeadCommit() -> Commit? {
        for branch in self.branches {
            if branch.name == self.main {
                return self.commits[branch.head]
            }
        }
        return nil
    }
    
    func topologicalSortCommits() -> [Commit]? {
            var visited = Set<Sha>()
            var stack = [Commit]()
            var childrenMap = Dictionary<Sha, [Commit]>()
            
            // Invert the parent relationship to a child relationship
            for commit in self.commits.values {
                for parent in commit.parent {
                    childrenMap[parent.sha, default: []].append(commit)
                }
            }
            
            // Find the commits with no parents (roots)
            let rootCommits = self.commits.values.filter { $0.parent.isEmpty }
            
            // Depth-First Search
            func dfs(commit: Commit) {
                visited.insert(commit.sha)
                if let children = childrenMap[commit.sha] {
                    for child in children {
                        if !visited.contains(child.sha) {
                            dfs(commit: child)
                        }
                    }
                }
                stack.append(commit)
            }
            
            // Apply DFS for each root commit
            for commit in rootCommits {
                if !visited.contains(commit.sha) {
                    dfs(commit: commit)
                }
            }
            
            return stack.reversed()  // The topologically sorted commits
        }
}


